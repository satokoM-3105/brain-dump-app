-- RLS 仕様書（docs/05_RLS仕様書.md）に基づくポリシー設定
-- 前提: brain_dumps.user_id 列が存在すること（20260531_01 / 20260531_02 適用済み）

-- ============================================================
-- brain_dumps
-- ============================================================

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
  using (user_id = auth.uid());

create policy "brain_dumps_delete_own"
  on public.brain_dumps
  for delete
  to authenticated
  using (user_id = auth.uid());

-- ============================================================
-- categories
-- ============================================================

alter table public.categories enable row level security;

drop policy if exists "categories_select_anon" on public.categories;
drop policy if exists "categories_select_authenticated" on public.categories;

create policy "categories_select_authenticated"
  on public.categories
  for select
  to authenticated
  using (true);
