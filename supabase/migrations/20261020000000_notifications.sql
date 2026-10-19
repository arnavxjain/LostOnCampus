-- In-app notifications
--
-- A row is created for the item's owner whenever the item changes to
-- 'at_security' (a finder handed it in) or 'returned' (security completed the
-- trace). The pickup code is never copied here; it stays in handover_codes.

create type public.notification_type as enum ('item_found', 'item_collected');

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  item_id uuid references public.items (id) on delete cascade,
  type public.notification_type not null,
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_created_idx on public.notifications (user_id, created_at desc);

---------------------------------------------------------------------------
-- Privileges + RLS: users read their own notifications and can only change
-- read_at. Rows are created by the trigger below, never by clients.
---------------------------------------------------------------------------

revoke all on public.notifications from anon, authenticated;
grant select, delete on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

alter table public.notifications enable row level security;

create policy "Users read their own notifications"
  on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));

create policy "Users mark their own notifications read"
  on public.notifications for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "Users delete their own notifications"
  on public.notifications for delete to authenticated
  using (user_id = (select auth.uid()));

---------------------------------------------------------------------------
-- Trigger: notify the owner when their item's status changes
---------------------------------------------------------------------------

create function private.notify_item_status()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_note text;
begin
  if new.status = 'at_security' then
    select h.note into v_note
    from public.handovers h
    where h.item_id = new.id and h.status = 'at_security'
    order by h.created_at desc
    limit 1;

    insert into public.notifications (user_id, item_id, type, title, body)
    values (
      new.owner_id, new.id, 'item_found',
      'Your item was found!',
      format('"%s" was handed to security. Finder''s note: %s. Open it to see your pickup code.',
             new.title, coalesce(v_note, 'none'))
    );
  elsif new.status = 'returned' then
    insert into public.notifications (user_id, item_id, type, title, body)
    values (
      new.owner_id, new.id, 'item_collected',
      'Item collected',
      format('"%s" was handed back to you. Glad you got it back!', new.title)
    );
  end if;
  return new;
end;
$$;

create trigger on_item_status_changed
  after update of status on public.items
  for each row
  when (old.status is distinct from new.status)
  execute function private.notify_item_status();

---------------------------------------------------------------------------
-- Realtime: the owner's app shows a live ping on insert.
---------------------------------------------------------------------------

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;
