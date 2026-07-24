-- Equipment module (CRUD only — no photos, inspections, valuation, or
-- categorization yet; those are separate tenant-scoped tables to be added
-- later, referencing public.equipment.id).
--
-- Safe to rerun: table/index/function/trigger definitions are idempotent,
-- and each policy is dropped immediately before being recreated. No existing
-- table or data is dropped.

create table if not exists public.equipment (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  asset_name text not null,
  manufacturer text not null,
  model text not null,
  serial_number text,
  year integer,
  hours numeric,
  location text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_equipment_company
  on public.equipment (company_id);

create index if not exists idx_equipment_company_serial
  on public.equipment (company_id, serial_number);

create or replace function public.set_equipment_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_equipment_updated_at on public.equipment;
create trigger trg_equipment_updated_at
  before update on public.equipment
  for each row
  execute function public.set_equipment_updated_at();

alter table public.equipment enable row level security;

-- Table privileges allow authenticated clients to query/insert/update rows;
-- RLS below remains the tenant-isolation boundary for which rows are
-- actually visible or writable. No delete privilege — this sprint is
-- create/read/update only, per current scope.
grant select, insert, update on public.equipment to authenticated;

drop policy if exists "company members can select their equipment"
  on public.equipment;
create policy "company members can select their equipment"
  on public.equipment
  for select
  to authenticated
  using (
    company_id = private.current_user_company_id()
  );

drop policy if exists "company members can insert their equipment"
  on public.equipment;
create policy "company members can insert their equipment"
  on public.equipment
  for insert
  to authenticated
  with check (
    company_id = private.current_user_company_id()
  );

drop policy if exists "company members can update their equipment"
  on public.equipment;
create policy "company members can update their equipment"
  on public.equipment
  for update
  to authenticated
  using (
    company_id = private.current_user_company_id()
  )
  with check (
    company_id = private.current_user_company_id()
  );
