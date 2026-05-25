-- FR-07 カテゴリ管理: categories マスタ作成、brain_dumps への category_id 追加、仮データ 5 件
-- 適用順: categories → brain_dumps 列追加 → インデックス → INSERT

-- ---------------------------------------------------------------------------
-- 1. カテゴリマスタ
-- ---------------------------------------------------------------------------

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

comment on table public.categories is 'メモ用カテゴリのマスタ';

-- ---------------------------------------------------------------------------
-- 2. メモテーブルへのカテゴリ列（任意・NULL 可）
-- ---------------------------------------------------------------------------

alter table public.brain_dumps
  add column if not exists category_id uuid references public.categories (id) on delete set null;

comment on column public.brain_dumps.category_id is 'カテゴリ（任意。未設定時は NULL）';

-- ---------------------------------------------------------------------------
-- 3. インデックス
-- ---------------------------------------------------------------------------

create index if not exists brain_dumps_category_id_idx
  on public.brain_dumps (category_id);

create index if not exists brain_dumps_created_at_idx
  on public.brain_dumps (created_at desc);

-- ---------------------------------------------------------------------------
-- 4. カテゴリ仮データ（5 件）
-- ---------------------------------------------------------------------------

insert into public.categories (name) values
  ('仕事'),
  ('プライベート'),
  ('アイデア'),
  ('学習'),
  ('その他')
on conflict (name) do nothing;
