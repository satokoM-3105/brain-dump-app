-- FR-08: brain_dumps に user_id 列を追加（nullable、auth.users 参照）

alter table public.brain_dumps
  add column if not exists user_id uuid references auth.users (id);

comment on column public.brain_dumps.user_id is 'メモの所有者（Supabase Auth ユーザ ID）';
