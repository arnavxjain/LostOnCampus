-- Campus Lost & Found: initial schema
--
-- Tables: floors, profiles, items, handovers, handover_codes
-- Storage: item-images bucket (public read, owner-folder writes)
--
-- Status changes are never written directly by clients:
--   lost -> found_pending        trigger on handover insert (finder taps "I Found This")
--   found_pending -> at_security Edge Function, service role (guard taps "Received", Phase 7)
--   at_security -> returned      security-definer RPC (guard verifies OTP, Phase 7)

create extension if not exists pgcrypto with schema extensions;

-- Helpers used by RLS policies live in a schema that is not exposed through the API.
create schema if not exists private;
grant usage on schema private to authenticated;

---------------------------------------------------------------------------
-- Types
---------------------------------------------------------------------------

create type public.user_role as enum ('student', 'guard');

create type public.item_category as enum (
  'electronics', 'id_card', 'keys', 'wallet', 'bag', 'clothing', 'books', 'bottle', 'other'
);

create type public.item_status as enum ('lost', 'found_pending', 'at_security', 'returned');

create type public.handover_status as enum ('pending_dropoff', 'at_security', 'collected');

---------------------------------------------------------------------------
-- Tables
---------------------------------------------------------------------------

-- Security desks. Seeded manually (see supabase/seed.sql).
create table public.floors (
  id smallint generated always as identity primary key,
  name text not null unique check (length(trim(name)) > 0),
  sort_order smallint not null default 0,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  phone text,
  role public.user_role not null default 'student',
  floor_id smallint references public.floors (id),
  created_at timestamptz not null default now(),
  -- Guards always have a desk; students never do.
  constraint profiles_guard_floor_chk check ((role = 'guard') = (floor_id is not null))
);

create table public.items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  title text not null check (length(trim(title)) between 1 and 100),
  description text check (length(description) <= 1000),
  category public.item_category not null default 'other',
  image_url text,
  status public.item_status not null default 'lost',
  created_at timestamptz not null default now()
);

create table public.handovers (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items (id) on delete cascade,
  finder_id uuid not null default auth.uid() references public.profiles (id),
  floor_id smallint not null references public.floors (id),
  guard_id uuid references public.profiles (id),
  storage_note text check (length(storage_note) <= 200),
  status public.handover_status not null default 'pending_dropoff',
  created_at timestamptz not null default now(),
  received_at timestamptz,
  collected_at timestamptz,
  expires_at timestamptz
);

-- OTP for a handover. Only the item's owner can read it; nobody else can touch it
-- except the service role (Edge Function) and security-definer functions.
-- The hash lives here rather than on handovers so guards can't brute-force it
-- (a 6-digit code has only 1M possibilities).
create table public.handover_codes (
  handover_id uuid primary key references public.handovers (id) on delete cascade,
  code text not null check (code ~ '^\d{6}$'),
  otp_hash text not null,
  failed_attempts smallint not null default 0,
  created_at timestamptz not null default now()
);

---------------------------------------------------------------------------
-- Indexes
---------------------------------------------------------------------------

create index items_status_created_idx on public.items (status, created_at desc);
create index items_owner_idx on public.items (owner_id);
create index handovers_floor_status_idx on public.handovers (floor_id, status);
create index handovers_finder_idx on public.handovers (finder_id);
-- At most one open handover per item.
create unique index handovers_one_open_per_item
  on public.handovers (item_id) where status <> 'collected';

---------------------------------------------------------------------------
-- RLS helper functions (security definer: they bypass RLS, so policies on
-- items and handovers can reference each other without infinite recursion)
---------------------------------------------------------------------------

-- The signed-in guard's floor, or null for students / signed-out callers.
create function private.guard_floor_id()
returns smallint
language sql stable security definer set search_path = ''
as $$
  select floor_id from public.profiles where id = auth.uid() and role = 'guard'
$$;

create function private.owns_item(p_item_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.items where id = p_item_id and owner_id = auth.uid())
$$;

create function private.item_is_lost(p_item_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.items where id = p_item_id and status = 'lost')
$$;

-- True if the caller is the finder of, or the guard responsible for, a handover of this item.
create function private.involved_in_item_handover(p_item_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.handovers h
    where h.item_id = p_item_id
      and (h.finder_id = auth.uid() or h.floor_id = private.guard_floor_id())
  )
$$;

create function private.owns_handover(p_handover_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.handovers h
    join public.items i on i.id = h.item_id
    where h.id = p_handover_id and i.owner_id = auth.uid()
  )
$$;

revoke all on all functions in schema private from public;
grant execute on function
  private.guard_floor_id(),
  private.owns_item(uuid),
  private.item_is_lost(uuid),
  private.involved_in_item_handover(uuid),
  private.owns_handover(uuid)
to authenticated;

---------------------------------------------------------------------------
-- Triggers
---------------------------------------------------------------------------

-- Create a profile for every new auth user from sign-up metadata.
-- Role is always 'student'; guards are promoted manually.
create function private.handle_new_user()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.raw_user_meta_data ->> 'phone'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- Finder created a handover: the item is no longer simply "lost".
create function private.handle_new_handover()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.items set status = 'found_pending' where id = new.item_id and status = 'lost';
  if not found then
    raise exception 'Item % is not available to be found', new.item_id using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger on_handover_created
  after insert on public.handovers
  for each row execute function private.handle_new_handover();

-- Profiles for users who signed up before this migration.
insert into public.profiles (id, full_name, phone)
select id, coalesce(raw_user_meta_data ->> 'full_name', ''), raw_user_meta_data ->> 'phone'
from auth.users
on conflict (id) do nothing;

---------------------------------------------------------------------------
-- Privileges. Column-level grants stop clients from writing fields that only
-- triggers / server functions may change (role, floor, status, guard_id, ...).
---------------------------------------------------------------------------

revoke all on public.floors, public.profiles, public.items, public.handovers, public.handover_codes
  from anon, authenticated;

grant select on public.floors to authenticated;

grant select on public.profiles to authenticated;
grant update (full_name, phone) on public.profiles to authenticated;

grant select, delete on public.items to authenticated;
grant insert (title, description, category, image_url) on public.items to authenticated;
grant update (title, description, category, image_url) on public.items to authenticated;

grant select on public.handovers to authenticated;
grant insert (item_id, floor_id) on public.handovers to authenticated;
grant update (storage_note) on public.handovers to authenticated;

grant select on public.handover_codes to authenticated;

---------------------------------------------------------------------------
-- Row Level Security
---------------------------------------------------------------------------

alter table public.floors enable row level security;
alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.handovers enable row level security;
alter table public.handover_codes enable row level security;

-- floors
create policy "Signed-in users can read floors"
  on public.floors for select to authenticated
  using (true);

-- profiles
create policy "Users can read their own profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- items
create policy "Read lost items, own items, and items you're handing over"
  on public.items for select to authenticated
  using (
    status = 'lost'
    or owner_id = (select auth.uid())
    or private.involved_in_item_handover(id)
  );

create policy "Owners can post items"
  on public.items for insert to authenticated
  with check (owner_id = (select auth.uid()) and status = 'lost');

create policy "Owners can edit their items"
  on public.items for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

-- Deleting once a finder is involved would orphan the guard's handover.
create policy "Owners can delete their items while still lost"
  on public.items for delete to authenticated
  using (owner_id = (select auth.uid()) and status = 'lost');

-- handovers
create policy "Finders, owners and floor guards can read handovers"
  on public.handovers for select to authenticated
  using (
    finder_id = (select auth.uid())
    or floor_id = (select private.guard_floor_id())
    or private.owns_item(item_id)
  );

create policy "Anyone but the owner can report a lost item found"
  on public.handovers for insert to authenticated
  with check (
    finder_id = (select auth.uid())
    and status = 'pending_dropoff'
    and guard_id is null
    and not private.owns_item(item_id)
    and private.item_is_lost(item_id)
  );

create policy "Guards can update handovers on their floor"
  on public.handovers for update to authenticated
  using (floor_id = (select private.guard_floor_id()))
  with check (floor_id = (select private.guard_floor_id()));

-- handover_codes: owner read-only. No insert/update/delete policies.
create policy "Owners can read the code for their own item"
  on public.handover_codes for select to authenticated
  using (private.owns_handover(handover_id));

---------------------------------------------------------------------------
-- Storage: item-images
-- Public read via public URL. Uploads go to "<user id>/<file>" and only the
-- uploader can write or delete inside their folder.
---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'item-images', 'item-images', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do nothing;

create policy "Users can upload item images to their folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'item-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can update their item images"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'item-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can delete their item images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'item-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
