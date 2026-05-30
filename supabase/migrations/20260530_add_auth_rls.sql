-- 認証導入: user_id 再追加、RLS、INSERT トリガ
-- 匿名時代のメモ（所有者なし）は削除する

alter table public.brain_dumps
  add column if not exists user_id uuid references auth.users (id) on delete cascade;

delete from public.brain_dumps where user_id is null;

alter table public.brain_dumps
  alter column user_id set not null;

create index if not exists brain_dumps_user_id_created_at_idx
  on public.brain_dumps (user_id, created_at desc);

create or replace function public.set_brain_dump_user_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.user_id := auth.uid();
  return new;
end;
$$;

drop trigger if exists brain_dumps_set_user_id on public.brain_dumps;

create trigger brain_dumps_set_user_id
  before insert on public.brain_dumps
  for each row
  execute function public.set_brain_dump_user_id();

alter table public.brain_dumps enable row level security;

drop policy if exists "brain_dumps_select_own" on public.brain_dumps;
drop policy if exists "brain_dumps_insert_own" on public.brain_dumps;
drop policy if exists "brain_dumps_update_own" on public.brain_dumps;
drop policy if exists "brain_dumps_delete_own" on public.brain_dumps;

create policy "brain_dumps_select_own"
  on public.brain_dumps
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "brain_dumps_insert_own"
  on public.brain_dumps
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "brain_dumps_update_own"
  on public.brain_dumps
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "brain_dumps_delete_own"
  on public.brain_dumps
  for delete
  to authenticated
  using (user_id = auth.uid());
