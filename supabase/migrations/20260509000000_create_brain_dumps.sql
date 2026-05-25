-- brain_dumps: ブレインダンプ用メモテーブル
-- RLS はまだ有効にしない（後続マイグレーションでポリシーと併せて有効化する想定）

create table public.brain_dumps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  content text not null,
  created_at timestamptz not null default now()
);

create index brain_dumps_user_id_created_at_idx
  on public.brain_dumps (user_id, created_at desc);

comment on table public.brain_dumps is 'ユーザー別メモ（思考・アイデアのテキスト保存）';
