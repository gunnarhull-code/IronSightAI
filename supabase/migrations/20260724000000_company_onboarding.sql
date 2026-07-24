-- Minimal tenancy schema for company onboarding (Sprint 1).
-- Aligns with docs/04-data-model.md companies + user_profiles, plus updated_at
-- on companies as required by the app Company entity.
--
-- create_company_for_current_user is SECURITY DEFINER so a brand-new user can
-- create their first company and owner profile before any RLS company_id
-- lookup would succeed.

create extension if not exists pgcrypto;

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  logo_url text,
  report_footer_text text,
  region text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.companies
  add column if not exists region text;

alter table public.companies
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.user_profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  company_id uuid not null references public.companies (id),
  full_name text not null,
  role text not null check (role in ('owner', 'admin', 'manager', 'rep')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_user_profiles_company
  on public.user_profiles (company_id);

create schema if not exists private;

create or replace function private.current_user_company_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select company_id
  from public.user_profiles
  where id = auth.uid()
$$;

revoke all on function private.current_user_company_id() from public;
grant usage on schema private to authenticated;
grant execute on function private.current_user_company_id()
  to authenticated;

alter table public.companies enable row level security;
alter table public.user_profiles enable row level security;

-- Table privileges allow authenticated clients to query these tables; RLS
-- below remains the tenant-isolation boundary for which rows are visible.
grant select on public.user_profiles to authenticated;
grant select on public.companies to authenticated;

-- Members can read their own company.
drop policy if exists "company members can select their company"
  on public.companies;
create policy "company members can select their company"
  on public.companies
  for select
  using (
    id = private.current_user_company_id()
  );

-- Members can read profiles in their company (roster / multi-user ready).
drop policy if exists "company members can select profiles in their company"
  on public.user_profiles;
create policy "company members can select profiles in their company"
  on public.user_profiles
  for select
  using (
    company_id = private.current_user_company_id()
  );

create or replace function public.set_companies_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_companies_updated_at on public.companies;
create trigger trg_companies_updated_at
  before update on public.companies
  for each row
  execute function public.set_companies_updated_at();

create or replace function public.create_company_for_current_user(p_name text)
returns public.companies
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  trimmed_name text := trim(p_name);
  base_slug text;
  unique_slug text;
  new_company public.companies;
  existing_company_id uuid;
  display_name text;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if trimmed_name is null or trimmed_name = '' then
    raise exception 'Company name is required';
  end if;

  select company_id
    into existing_company_id
  from public.user_profiles
  where id = current_user_id;

  if existing_company_id is not null then
    raise exception 'User already belongs to a company';
  end if;

  base_slug := lower(regexp_replace(trimmed_name, '[^a-zA-Z0-9]+', '-', 'g'));
  base_slug := trim(both '-' from base_slug);
  if base_slug = '' then
    base_slug := 'company';
  end if;
  unique_slug := base_slug || '-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);

  insert into public.companies (name, slug)
  values (trimmed_name, unique_slug)
  returning * into new_company;

  display_name := coalesce(
    nullif(trim(both from (auth.jwt() -> 'user_metadata' ->> 'full_name')), ''),
    nullif(split_part(coalesce(auth.jwt() ->> 'email', ''), '@', 1), ''),
    'Owner'
  );

  insert into public.user_profiles (id, company_id, full_name, role)
  values (current_user_id, new_company.id, display_name, 'owner');

  return new_company;
end;
$$;

revoke all on function public.create_company_for_current_user(text) from public;
grant execute on function public.create_company_for_current_user(text)
  to authenticated;
