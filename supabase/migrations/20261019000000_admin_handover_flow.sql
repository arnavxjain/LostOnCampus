-- Admin handover flow
--
-- Replaces the per-floor guard flow from the initial schema:
--   1. Finder hands the item to any security desk, taps "Found" and writes a
--      mandatory note saying where they left it  -> public.report_found()
--   2. The item is immediately 'at_security' and gets a 6-digit code.
--      The owner and every admin can read the code; the finder never can.
--   3. The owner tells security the code; the admin hands over the matching
--      item and taps "Trace complete"              -> public.complete_handover()
--
-- Roles: 'guard' becomes 'admin'. Admins have no floor; they see every item.

---------------------------------------------------------------------------
-- 1. Drop policies, triggers and helpers that depend on what changes below
---------------------------------------------------------------------------

drop policy "Read lost items, own items, and items you're handing over" on public.items;
drop policy "Owners can post items" on public.items;
drop policy "Owners can edit their items" on public.items;
drop policy "Owners can delete their items while still lost" on public.items;
drop policy "Finders, owners and floor guards can read handovers" on public.handovers;
drop policy "Anyone but the owner can report a lost item found" on public.handovers;
drop policy "Guards can update handovers on their floor" on public.handovers;
drop policy "Owners can read the code for their own item" on public.handover_codes;

drop trigger on_handover_created on public.handovers;
drop function private.handle_new_handover();
drop function private.guard_floor_id();
drop function private.item_is_lost(uuid);
drop function private.involved_in_item_handover(uuid);

---------------------------------------------------------------------------
-- 2. Roles: guard -> admin, no floors
---------------------------------------------------------------------------

alter type public.user_role rename value 'guard' to 'admin';

alter table public.profiles drop constraint profiles_guard_floor_chk;
alter table public.profiles drop column floor_id;

---------------------------------------------------------------------------
-- 3. Handovers: free-text note instead of a floor, no separate "received" step
---------------------------------------------------------------------------

alter table public.handovers add column note text;
update public.handovers h
  set note = 'Left at ' || f.name || ' security'
  from public.floors f
  where f.id = h.floor_id;
alter table public.handovers
  alter column note set not null,
  add constraint handovers_note_check check (length(trim(note)) between 3 and 300);

alter table public.handovers rename column guard_id to completed_by;

drop index public.handovers_floor_status_idx;
drop index public.handovers_one_open_per_item;
alter table public.handovers
  drop column floor_id,
  drop column storage_note,
  drop column received_at,
  drop column expires_at;

drop table public.floors;

-- Handover status: created directly 'at_security', then 'collected'.
alter type public.handover_status rename to handover_status_old;
create type public.handover_status as enum ('at_security', 'collected');
alter table public.handovers
  alter column status drop default,
  alter column status type public.handover_status
    using (case when status::text = 'collected' then 'collected' else 'at_security' end)::public.handover_status,
  alter column status set default 'at_security';
drop type public.handover_status_old;

create unique index handovers_one_open_per_item
  on public.handovers (item_id) where status = 'at_security';

-- Item status: lost -> at_security -> returned ('found_pending' is gone).
alter type public.item_status rename to item_status_old;
create type public.item_status as enum ('lost', 'at_security', 'returned');
alter table public.items
  alter column status drop default,
  alter column status type public.item_status
    using (case when status::text = 'found_pending' then 'at_security' else status::text end)::public.item_status,
  alter column status set default 'lost';
drop type public.item_status_old;

---------------------------------------------------------------------------
-- 4. Codes: admins read them directly, so no hash or attempt counter.
--    Active codes are unique so a code always points at exactly one item.
---------------------------------------------------------------------------

alter table public.handover_codes
  drop column otp_hash,
  drop column failed_attempts,
  add column active boolean not null default true;

update public.handover_codes c
  set active = (h.status = 'at_security')
  from public.handovers h
  where h.id = c.handover_id;

create unique index handover_codes_active_code on public.handover_codes (code) where active;

---------------------------------------------------------------------------
-- 5. Privileges: handovers are only written through the functions below
---------------------------------------------------------------------------

revoke insert, update on public.handovers from authenticated;

---------------------------------------------------------------------------
-- 6. RLS helpers and policies
---------------------------------------------------------------------------

create function private.is_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
$$;

create function private.is_finder_of(p_item_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.handovers where item_id = p_item_id and finder_id = auth.uid())
$$;

revoke all on function private.is_admin(), private.is_finder_of(uuid) from public;
grant execute on function private.is_admin(), private.is_finder_of(uuid) to authenticated;

-- items
create policy "Read lost items, own items, items you found; admins read all"
  on public.items for select to authenticated
  using (
    status = 'lost'
    or owner_id = (select auth.uid())
    or (select private.is_admin())
    or private.is_finder_of(id)
  );

create policy "Owners can post items"
  on public.items for insert to authenticated
  with check (owner_id = (select auth.uid()) and status = 'lost');

create policy "Owners can edit their items"
  on public.items for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "Owners can delete their items while still lost"
  on public.items for delete to authenticated
  using (owner_id = (select auth.uid()) and status = 'lost');

-- handovers (read-only for clients)
create policy "Finders, owners and admins can read handovers"
  on public.handovers for select to authenticated
  using (
    finder_id = (select auth.uid())
    or private.owns_item(item_id)
    or (select private.is_admin())
  );

-- handover_codes: owner and admins only. Never the finder.
create policy "Owners and admins can read codes"
  on public.handover_codes for select to authenticated
  using (private.owns_handover(handover_id) or (select private.is_admin()));

---------------------------------------------------------------------------
-- 7. Server functions called by the app
---------------------------------------------------------------------------

-- Finder taps "Found". Creates the handover, generates the code and moves the
-- item to 'at_security' in one transaction. Returns the handover id.
create function public.report_found(p_item_id uuid, p_note text)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_note text := trim(coalesce(p_note, ''));
  v_item public.items%rowtype;
  v_handover_id uuid;
  v_bytes bytea;
  v_code text;
begin
  if v_uid is null then
    raise exception 'You need to be signed in.' using errcode = 'P0001';
  end if;
  if length(v_note) < 3 then
    raise exception 'Add a note saying which security desk has the item.' using errcode = 'P0001';
  end if;
  if length(v_note) > 300 then
    raise exception 'Keep the note under 300 characters.' using errcode = 'P0001';
  end if;

  select * into v_item from public.items where id = p_item_id for update;
  if not found or v_item.status <> 'lost' then
    raise exception 'This item has already been found or removed.' using errcode = 'P0001';
  end if;
  if v_item.owner_id = v_uid then
    raise exception 'You can''t report your own item as found.' using errcode = 'P0001';
  end if;

  insert into public.handovers (item_id, finder_id, note)
  values (p_item_id, v_uid, v_note)
  returning id into v_handover_id;

  -- Cryptographically random 6-digit code, unique among active codes.
  loop
    v_bytes := extensions.gen_random_bytes(4);
    v_code := lpad((
      ((get_byte(v_bytes, 0)::bigint << 24) | (get_byte(v_bytes, 1) << 16)
        | (get_byte(v_bytes, 2) << 8) | get_byte(v_bytes, 3)) % 1000000
    )::text, 6, '0');
    begin
      insert into public.handover_codes (handover_id, code) values (v_handover_id, v_code);
      exit;
    exception when unique_violation then
      -- Another item at security already uses this code; draw again.
    end;
  end loop;

  update public.items set status = 'at_security' where id = p_item_id;
  return v_handover_id;
end;
$$;

-- Admin taps "Trace complete" after the owner gives the matching code.
create function public.complete_handover(p_handover_id uuid, p_code text)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_item_id uuid;
begin
  if not private.is_admin() then
    raise exception 'Only security staff can complete a handover.' using errcode = 'P0001';
  end if;

  select h.item_id into v_item_id
  from public.handovers h
  join public.handover_codes c on c.handover_id = h.id
  where h.id = p_handover_id
    and h.status = 'at_security'
    and c.active
    and c.code = trim(coalesce(p_code, ''))
  for update of h;

  if v_item_id is null then
    raise exception 'That code doesn''t match this item. Don''t hand it over.' using errcode = 'P0001';
  end if;

  update public.handovers
    set status = 'collected', collected_at = now(), completed_by = auth.uid()
    where id = p_handover_id;
  update public.handover_codes set active = false where handover_id = p_handover_id;
  update public.items set status = 'returned' where id = v_item_id;
end;
$$;

revoke all on function public.report_found(uuid, text), public.complete_handover(uuid, text) from public, anon;
grant execute on function public.report_found(uuid, text), public.complete_handover(uuid, text) to authenticated;

---------------------------------------------------------------------------
-- 8. Realtime: owners get a live ping, admin lists refresh live.
--    Realtime applies the RLS policies above to every subscriber.
---------------------------------------------------------------------------

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.items;
  end if;
end;
$$;
