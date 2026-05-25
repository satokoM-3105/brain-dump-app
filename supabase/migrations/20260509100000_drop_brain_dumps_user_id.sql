-- user_id 列を削除（外部キーは列削除で一緒に消えます）
-- 先に user_id を含むインデックスを除く

drop index if exists public.brain_dumps_user_id_created_at_idx;

alter table public.brain_dumps
  drop column if exists user_id;
