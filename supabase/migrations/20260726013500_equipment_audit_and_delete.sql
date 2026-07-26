-- Sprint 002 equipment polish: audit metadata and explicit equipment delete.
--
-- Adds nullable audit user references for existing rows, records current auth
-- users on future inserts/updates, and grants tenant-scoped deletes without
-- weakening existing company isolation.

alter table public.equipment
  add column if not exists created_by uuid references auth.users (id) on delete set null,
  add column if not exists updated_by uuid references auth.users (id) on delete set null;

create index if not exists idx_equipment_created_by
  on public.equipment (created_by);

create index if not exists idx_equipment_updated_by
  on public.equipment (updated_by);

create or replace function public.set_equipment_audit_fields()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    new.created_by = coalesce(auth.uid(), new.created_by);
    new.updated_by = coalesce(auth.uid(), new.updated_by);
  elsif tg_op = 'UPDATE' then
    new.created_by = old.created_by;
    new.updated_by = auth.uid();
    new.updated_at = now();
  end if;

  return new;
end;
$$;

drop trigger if exists trg_equipment_updated_at on public.equipment;
drop trigger if exists trg_equipment_audit_fields on public.equipment;
create trigger trg_equipment_audit_fields
  before insert or update on public.equipment
  for each row
  execute function public.set_equipment_audit_fields();

grant delete on public.equipment to authenticated;

drop policy if exists "company members can delete their equipment"
  on public.equipment;
create policy "company members can delete their equipment"
  on public.equipment
  for delete
  to authenticated
  using (
    company_id = private.current_user_company_id()
  );
