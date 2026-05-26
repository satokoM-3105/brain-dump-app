-- categories を anon（未ログイン）から読めるようにする
-- ドロップダウン用。RLS 有効時に選択肢が0件になる問題を防ぐ

alter table public.categories enable row level security;

drop policy if exists "categories_select_anon" on public.categories;

create policy "categories_select_anon"
  on public.categories
  for select
  to anon, authenticated
  using (true);
