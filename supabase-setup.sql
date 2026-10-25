-- Run once in the Supabase SQL Editor as the project owner.
-- These tables are dedicated to NEXUS; no existing application tables are changed.
begin;
create table if not exists public.nexus_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('member','operator','admin'))
);
create table if not exists public.nexus_vault (
  id bigint generated always as identity primary key,
  title text not null,
  body text not null,
  min_role text not null check (min_role in ('operator','admin'))
);
alter table public.nexus_profiles enable row level security;
alter table public.nexus_vault enable row level security;
revoke all on public.nexus_profiles from anon, authenticated;
revoke all on public.nexus_vault from anon, authenticated;
grant select on public.nexus_profiles to authenticated;
grant select on public.nexus_vault to authenticated;
-- A user can read their own clearance but cannot write it.
drop policy if exists nexus_read_own_profile on public.nexus_profiles;
create policy nexus_read_own_profile on public.nexus_profiles
for select to authenticated using (id = (select auth.uid()));
-- The database, not the HTML route guard, enforces vault compartment access.
drop policy if exists nexus_read_permitted_vault on public.nexus_vault;
create policy nexus_read_permitted_vault on public.nexus_vault
for select to authenticated using (
  exists (
    select 1 from public.nexus_profiles p
    where p.id = (select auth.uid())
      and (p.role = 'admin' or (p.role = 'operator' and min_role = 'operator'))
  )
);
create or replace function public.nexus_create_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.nexus_profiles (id, role) values (new.id, 'member')
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function public.nexus_create_profile() from public, anon, authenticated;
drop trigger if exists nexus_user_created on auth.users;
create trigger nexus_user_created after insert on auth.users
for each row execute function public.nexus_create_profile();
-- Backfill accounts that already exist. Never derive clearance from user metadata.
insert into public.nexus_profiles (id, role)
select id, 'member' from auth.users on conflict (id) do nothing;
-- Harmless sample server-side records. Replace them in the dashboard.
insert into public.nexus_vault (title, body, min_role)
select 'OPERATOR BRIEF / SAMPLE', 'This sample record is returned only to operators and admins.', 'operator'
where not exists (select 1 from public.nexus_vault where title = 'OPERATOR BRIEF / SAMPLE');
insert into public.nexus_vault (title, body, min_role)
select 'ADMIN COMPARTMENT / SAMPLE', 'This sample record is returned only to admins.', 'admin'
where not exists (select 1 from public.nexus_vault where title = 'ADMIN COMPARTMENT / SAMPLE');
commit;
-- To promote YOUR account, run this separately after replacing the email:
-- update public.nexus_profiles set role = 'admin'
-- where id = (select id from auth.users where email = 'YOUR_EMAIL_HERE');
-- Other allowed roles: member, operator. Assign them only through trusted admin tooling.
