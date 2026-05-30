-- FR-08: 既存メモの user_id を所有者ユーザ ID に更新
-- 実行前に 20260531_01_add_brain_dumps_user_id.sql を適用すること

update public.brain_dumps
set user_id = '2dccb8f5-9c2d-4af1-853a-3c9ce1c0cc0e'
where user_id is null;
