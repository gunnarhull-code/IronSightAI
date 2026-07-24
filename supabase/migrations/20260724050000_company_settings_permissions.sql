-- Company Settings permissions.
--
-- Adds the table privilege and RLS policy needed for owners to update their
-- own company's basic settings (name and region). No tables or data are
-- dropped. RLS remains the tenant boundary.

create schema if not exists private;

create or replace function private.current_user_company_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role
  from public.user_profiles
  where id = auth.uid()
$$;

revoke all on function private.current_user_company_role() from public;
grant usage on schema private to authenticated;
grant execute on function private.current_user_company_role()
  to authenticated;

alter table public.companies enable row level security;
alter table public.user_profiles enable row level security;

grant select on public.user_profiles to authenticated;
grant select on public.companies to authenticated;
grant update (name, region) on public.companies to authenticated;

drop policy if exists "owners can update their company settings"
  on public.companies;

create policy "owners can update their company settings"
  on public.companies
  for update
  to authenticated
  using (
    id = private.current_user_company_id()
    and private.current_user_company_role() = 'owner'
  )
  with check (
    id = private.current_user_company_id()
    and private.current_user_company_role() = 'owner'
  );
