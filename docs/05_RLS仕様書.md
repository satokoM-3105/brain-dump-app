# ブレインダンプアプリ — RLS 仕様書

## 1. 概要

| 項目 | 内容 |
|------|------|
| 目的 | **ログイン済みユーザーが自分が作成したデータのみ操作できる** よう、DB レベルでアクセスを制限する |
| 方式 | Supabase / PostgreSQL の **Row Level Security（RLS）** |
| 対象テーブル | `brain_dumps`、`categories`（本書の対象はこの 2 テーブルのみ） |
| 根拠要求 | 要求仕様 **FR-08**（ユーザ別メモ管理）、**FR-09**（行レベルセキュリティ） |
| SQL | 本書では **ポリシー仕様のみ** 定義する。CREATE POLICY 等の SQL 生成・適用は別途 |

関連ドキュメント:

- **`docs/01_要求仕様書.md`** — 機能・非機能要求
- **`docs/02_DB仕様書.md`** — テーブル定義（`brain_dumps.user_id` 等）

---

## 2. 前提

### 2.1 認証

- クライアントは Supabase Auth でログインし、**JWT 付き**リクエストを送る。
- RLS の条件式では **`auth.uid()`**（ログイン中ユーザの UUID）を用いる。

### 2.2 所有者の識別（`brain_dumps`）

| カラム | 説明 |
|--------|------|
| `brain_dumps.user_id` | メモの所有者。`auth.users(id)` への外部キー |

**自分のデータ** とは、`brain_dumps.user_id = auth.uid()` を満たす行を指す。

### 2.3 `categories` の位置づけ

- `categories` は **全ユーザ共通のマスタ** で、`user_id` 列を持たない。
- ユーザが「作成したデータ」ではないため、**INSERT / UPDATE / DELETE は許可しない**。
- ドロップダウン用に **SELECT のみ** 許可する（要求仕様 FR-07）。

### 2.4 RLS の基本方針

| テーブル | RLS |
|----------|-----|
| `brain_dumps` | **有効** |
| `categories` | **有効** |

- ポリシーが存在しない操作・ロールは **拒否** される（デフォルト deny）。
- アプリ側の `.eq('user_id', user.id)`（機能仕様 F-12）と併用し、**アプリ＋DB の二重防御** とする。

---

## 3. ポリシー一覧（サマリ）

### 3.1 `brain_dumps`

| No. | ポリシー名（案） | 操作 | ロール | 条件（USING / WITH CHECK） |
|-----|------------------|------|--------|----------------------------|
| P-01 | `brain_dumps_select_own` | SELECT | `authenticated` | `user_id = auth.uid()` |
| P-02 | `brain_dumps_insert_own` | INSERT | `authenticated` | `WITH CHECK (user_id = auth.uid())` |
| P-03 | `brain_dumps_update_own` | UPDATE | `authenticated` | `USING (user_id = auth.uid())` かつ `WITH CHECK (user_id = auth.uid())` |
| P-04 | `brain_dumps_delete_own` | DELETE | `authenticated` | `user_id = auth.uid()` |

- **`anon`（未ログイン）**: ポリシーを設けない → すべて拒否。

### 3.2 `categories`

| No. | ポリシー名（案） | 操作 | ロール | 条件（USING / WITH CHECK） |
|-----|------------------|------|--------|----------------------------|
| P-05 | `categories_select_authenticated` | SELECT | `authenticated` | `true`（全行参照可） |
| P-06 | `categories_select_anon` | SELECT | `anon` | `true`（任意・未ログイン時の参照が必要な場合のみ） |

- **INSERT / UPDATE / DELETE**: ポリシーを設けない → `authenticated`・`anon` とも拒否。
- 本アプリはログイン後にカテゴリを取得するため、**P-06 は必須ではない**。SQL 生成時に P-05 のみでよい。

---

## 4. テーブル別詳細

### 4.1 `brain_dumps`

#### 4.1.1 SELECT（P-01）

| 項目 | 内容 |
|------|------|
| 目的 | 一覧・参照は **自分のメモのみ** |
| 許可ロール | `authenticated` |
| USING | `user_id = auth.uid()` |
| 拒否例 | 他ユーザの `user_id` を持つ行は返らない |

#### 4.1.2 INSERT（P-02）

| 項目 | 内容 |
|------|------|
| 目的 | 新規メモは **自分の `user_id` の行としてのみ** 作成 |
| 許可ロール | `authenticated` |
| WITH CHECK | `user_id = auth.uid()` |
| 拒否例 | 他ユーザ ID を `user_id` に指定した INSERT |

#### 4.1.3 UPDATE（P-03）

| 項目 | 内容 |
|------|------|
| 目的 | **自分のメモのみ** 更新 |
| 許可ロール | `authenticated` |
| USING | `user_id = auth.uid()`（更新対象行の判定） |
| WITH CHECK | `user_id = auth.uid()`（更新後の行の判定。`user_id` の改ざんも防止） |
| 拒否例 | 他ユーザの行のタイトル・本文変更、`user_id` のすり替え |

#### 4.1.4 DELETE（P-04）

| 項目 | 内容 |
|------|------|
| 目的 | **自分のメモのみ** 削除 |
| 許可ロール | `authenticated` |
| USING | `user_id = auth.uid()` |
| 拒否例 | 他ユーザの行の DELETE |

---

### 4.2 `categories`

#### 4.2.1 SELECT（P-05 / 任意 P-06）

| 項目 | 内容 |
|------|------|
| 目的 | カテゴリマスタの **参照のみ**（ドロップダウン・一覧表示名） |
| 許可ロール | `authenticated`（必須）。必要に応じて `anon`（P-06） |
| USING | `true` |
| 備考 | 行単位の所有者は存在しないため、「自分のデータのみ」は **メモ（`brain_dumps`）側** で担保する |

#### 4.2.2 INSERT / UPDATE / DELETE

| 項目 | 内容 |
|------|------|
| 目的 | 画面からのマスタ CRUD を禁止（要求仕様の対象外） |
| ポリシー | **作成しない**（デフォルト deny） |
| マスタ更新 | SQL Editor 等の管理者操作で行う |

---

## 5. 操作 × ロール マトリクス

### 5.1 `brain_dumps`

| 操作 | `anon` | `authenticated`（自分の行） | `authenticated`（他ユーザの行） |
|------|--------|-------------------------------|----------------------------------|
| SELECT | 拒否 | 許可 | 拒否 |
| INSERT | 拒否 | 許可（`user_id = auth.uid()`） | — |
| UPDATE | 拒否 | 許可 | 拒否 |
| DELETE | 拒否 | 許可 | 拒否 |

### 5.2 `categories`

| 操作 | `anon` | `authenticated` |
|------|--------|-----------------|
| SELECT | P-06 がある場合のみ許可 | 許可 |
| INSERT | 拒否 | 拒否 |
| UPDATE | 拒否 | 拒否 |
| DELETE | 拒否 | 拒否 |

---

## 6. 要求仕様との対応

| 要求 | RLS での担保 |
|------|----------------|
| FR-08: 自分のメモのみ参照・追加 | P-01, P-02 |
| FR-03 / FR-04: 他ユーザメモの編集・削除不可 | P-03, P-04（他行は USING で除外） |
| FR-09: ログイン済みユーザは自分が作成したデータのみ操作 | `brain_dumps` 全ポリシーで `user_id = auth.uid()` |
| FR-07: カテゴリドロップダウン | P-05（SELECT のみ） |
| AC-04 / AC-09 | 他ユーザの `brain_dumps` 行へのアクセス拒否 |

---

## 7. 適用時の注意（SQL 生成・運用時）

1. **適用順序（推奨）**: 各テーブルで `ENABLE ROW LEVEL SECURITY` → ポリシー CREATE（順序は SELECT → INSERT → UPDATE → DELETE でよい）。
2. **`brain_dumps.user_id`**: RLS 適用前に列が存在し、INSERT 時に正しい `user_id` が入ること（機能仕様 F-12）。
3. **既存ポリシー**: 同名ポリシーがある場合は DROP してから再 CREATE する想定でよい（SQL は別途）。
4. **service_role**: 本書は **anon / authenticated** のアプリアクセスのみ対象。管理用ロールは対象外。
5. **検証**: ユーザ A・B でログインし、A のメモが B から見えない・更新できないことを AC-09 で確認する。

### 7.1 適用用 SQL

| ファイル | 内容 |
|----------|------|
| `supabase/migrations/20260531_03_enable_rls_policies.sql` | RLS 有効化とポリシー（P-01〜P-05） |

**適用順序（重要）**

1. `20260531_01_add_brain_dumps_user_id.sql`（`user_id` 列追加）
2. `20260531_02_update_brain_dumps_user_id.sql`（既存データの `user_id` 更新）
3. **`20260531_03_enable_rls_policies.sql`（本 RLS 設定）**

### 7.2 Supabase SQL Editor での実行手順

1. [Supabase Dashboard](https://supabase.com/dashboard) を開き、対象プロジェクトを選択する。
2. 左メニューから **SQL Editor** を開く。
3. **New query** をクリックする。
4. `supabase/migrations/20260531_03_enable_rls_policies.sql` の内容をすべてコピーし、エディタに貼り付ける。
5. **Run**（または Ctrl+Enter）を押して実行する。
6. 結果に `Success. No rows returned` 等が表示され、エラーが出ないことを確認する。
7. **Table Editor** → `brain_dumps` → **RLS policies** で 4 件、`categories` で 1 件のポリシーが表示されることを確認する。
8. アプリにログインし、メモの一覧・保存・編集・削除とカテゴリドロップダウンが動作することを確認する。

---

## 8. 改訂履歴

| 版 | 日付 | 内容 |
|----|------|------|
| 1.0 | 2026-05-30 | 初版（`brain_dumps`・`categories` の RLS ポリシー定義） |
| 1.1 | 2026-05-30 | 適用 SQL・SQL Editor 手順を追加 |
