# Plan: Phase 2 — DB スキーマ & RLS

## Summary

Supabase PostgreSQL に全テーブル（profiles / friendships / friend_shares / sleep_records / sleep_goals）を作成し、行レベルセキュリティ（RLS）ポリシーとインデックスを設定する。Apple Sign In 完了時に profile を自動生成する DB トリガーも含む。ファイルの成果物は `supabase/migrations/001_initial_schema.sql` 1本で、Supabase MCP または SQL エディタで実行する。

## User Story

As a developer,
I want the Supabase database to have all tables with correct RLS policies,
So that Phase 3 以降で安全にデータを読み書きできる基盤が整う。

## Problem → Solution

テーブルなし → 全テーブル + RLS + インデックス + auth トリガーが揃った状態

## Metadata

- **Complexity**: Medium
- **Source PRD**: `.claude/PRPs/prds/sleep-tracker.prd.md`
- **PRD Phase**: Phase 2 — DB スキーマ & RLS
- **Estimated Files**: 1 新規（`supabase/migrations/001_initial_schema.sql`）

---

## UX Design

N/A — 純粋な DB 変更。ユーザー向け UI 変更なし。

---

## Mandatory Reading

| Priority | File | Lines | Why |
|---|---|---|---|
| P0 | `src/types/index.ts` | 全行 | DB スキーマと TypeScript 型の整合確認 |
| P0 | `src/lib/supabase.ts` | 全行 | クライアント設定（auth adapter）の確認 |
| P1 | `.claude/PRPs/prds/sleep-tracker.prd.md` | 118–155 | DBスキーマ概要と技術的意思決定 |

---

## Patterns to Mirror

### TYPE_DEFINITIONS
```typescript
// SOURCE: src/types/index.ts:1-53
// DB カラム名はスネークケース、TypeScript フィールドも同一名で定義済み
export type RecordMethod = 'now' | 'manual'
export interface SleepRecord {
  id: string
  user_id: string
  date: string             // 'YYYY-MM-DD'
  bedtime_at: string | null  // ISO 8601 UTC
  bedtime_method: RecordMethod | null
  ...
}
```

### RLS_HELPER_PATTERN
```sql
-- 友達関係の確認に使う共通パターン
exists (
  select 1 from friendships f
  where f.status = 'accepted'
    and (
      (f.requester_id = auth.uid() and f.addressee_id = <target_user_id>)
      or (f.addressee_id = auth.uid() and f.requester_id = <target_user_id>)
    )
)
```

---

## Files to Change

| File | Action | Justification |
|---|---|---|
| `supabase/migrations/001_initial_schema.sql` | CREATE | 全スキーマ・RLS・トリガーの正規定義 |

## NOT Building

- Supabase CLI のローカル開発環境（`supabase init` / `config.toml`）
- TypeScript 型の再生成（既存の `src/types/index.ts` はスキーマと整合済み）
- シードデータ（テストデータは Phase 2 完了後に SQL エディタで手動挿入）
- Edge Functions

---

## Step-by-Step Tasks

### Task 1: `supabase/migrations/` ディレクトリ作成

- **ACTION**: `supabase/migrations/` ディレクトリを作成する
- **IMPLEMENT**: `mkdir -p supabase/migrations`
- **VALIDATE**: ディレクトリが存在することを確認

---

### Task 2: `001_initial_schema.sql` を作成する

- **ACTION**: 以下の SQL を `supabase/migrations/001_initial_schema.sql` に書き込む
- **IMPLEMENT**: 下記の完全な SQL を使用すること（省略・改変禁止）

```sql
-- ============================================================
-- 001_initial_schema.sql
-- Sleep Tracker — 初期スキーマ
-- ============================================================

-- ============================================================
-- テーブル
-- ============================================================

-- profiles: auth.users と 1:1 対応
create table if not exists public.profiles (
  id           uuid primary key references auth.users on delete cascade,
  username     text unique not null,
  display_name text,
  push_token   text,
  created_at   timestamptz not null default now()
);

-- friendships: 友達リクエスト・承認
create table if not exists public.friendships (
  id           uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles on delete cascade,
  addressee_id uuid not null references public.profiles on delete cascade,
  status       text not null default 'pending'
                 check (status in ('pending', 'accepted')),
  created_at   timestamptz not null default now(),
  constraint friendships_unique      unique (requester_id, addressee_id),
  constraint friendships_no_self     check (requester_id <> addressee_id)
);

-- friend_shares: お気に入り = 実記録を共有する相手
create table if not exists public.friend_shares (
  user_id    uuid not null references public.profiles on delete cascade,
  friend_id  uuid not null references public.profiles on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  constraint friend_shares_no_self check (user_id <> friend_id)
);

-- sleep_records: 実際の就寝・起床記録
create table if not exists public.sleep_records (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles on delete cascade,
  date           date not null,
  bedtime_at     timestamptz,
  bedtime_method text check (bedtime_method in ('now', 'manual')),
  wake_at        timestamptz,
  wake_method    text check (wake_method in ('now', 'manual')),
  created_at     timestamptz not null default now(),
  constraint sleep_records_unique_date unique (user_id, date)
);

-- sleep_goals: 翌日目標宣言（不変 — UPDATE 禁止は RLS で強制）
create table if not exists public.sleep_goals (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles on delete cascade,
  target_date      date not null,
  target_bedtime   time not null,
  target_wake_time time not null,
  daily_goal       text,
  created_at       timestamptz not null default now(),
  constraint sleep_goals_unique_date unique (user_id, target_date)
);

-- ============================================================
-- インデックス
-- ============================================================

create index if not exists sleep_records_user_date on public.sleep_records (user_id, date desc);
create index if not exists sleep_goals_user_date   on public.sleep_goals   (user_id, target_date desc);
create index if not exists friendships_requester   on public.friendships   (requester_id);
create index if not exists friendships_addressee   on public.friendships   (addressee_id);
create index if not exists friend_shares_friend    on public.friend_shares (friend_id);

-- ============================================================
-- Auth トリガー: サインアップ時に profile を自動生成
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  _base     text;
  _username text;
begin
  -- メールのローカルパート（@より前）を base とし、UUID の先頭 6 文字でサフィックス
  -- → 衝突を回避しつつ可読性を確保。ユーザーは Phase 9 で自由に変更できる
  _base     := coalesce(
                 nullif(trim(split_part(new.email, '@', 1)), ''),
                 'user'
               );
  _username := _base || '_' || substr(replace(new.id::text, '-', ''), 1, 6);

  insert into public.profiles (id, username)
  values (new.id, _username);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- RLS 有効化
-- ============================================================

alter table public.profiles      enable row level security;
alter table public.friendships   enable row level security;
alter table public.friend_shares enable row level security;
alter table public.sleep_records enable row level security;
alter table public.sleep_goals   enable row level security;

-- ============================================================
-- RLS ポリシー: profiles
-- 認証済みユーザーは全プロフィール参照可（友達検索のため）
-- 書き込みは自分のみ
-- ============================================================

drop policy if exists "profiles: authenticated can select" on public.profiles;
create policy "profiles: authenticated can select" on public.profiles
  for select to authenticated using (true);

drop policy if exists "profiles: own insert" on public.profiles;
create policy "profiles: own insert" on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists "profiles: own update" on public.profiles;
create policy "profiles: own update" on public.profiles
  for update using (auth.uid() = id);

-- ============================================================
-- RLS ポリシー: friendships
-- ============================================================

drop policy if exists "friendships: select own" on public.friendships;
create policy "friendships: select own" on public.friendships
  for select using (
    auth.uid() = requester_id or auth.uid() = addressee_id
  );

drop policy if exists "friendships: insert as requester" on public.friendships;
create policy "friendships: insert as requester" on public.friendships
  for insert with check (auth.uid() = requester_id);

-- 受信側のみ status を更新できる（pending → accepted）
drop policy if exists "friendships: addressee can update" on public.friendships;
create policy "friendships: addressee can update" on public.friendships
  for update using (auth.uid() = addressee_id);

-- 双方が削除できる（友達解除）
drop policy if exists "friendships: delete own" on public.friendships;
create policy "friendships: delete own" on public.friendships
  for delete using (
    auth.uid() = requester_id or auth.uid() = addressee_id
  );

-- ============================================================
-- RLS ポリシー: friend_shares
-- ============================================================

-- 自分の共有設定 OR 自分に共有されているか確認（Phase 7 で利用）
drop policy if exists "friend_shares: select own or targeted" on public.friend_shares;
create policy "friend_shares: select own or targeted" on public.friend_shares
  for select using (
    auth.uid() = user_id or auth.uid() = friend_id
  );

drop policy if exists "friend_shares: own insert" on public.friend_shares;
create policy "friend_shares: own insert" on public.friend_shares
  for insert with check (auth.uid() = user_id);

drop policy if exists "friend_shares: own delete" on public.friend_shares;
create policy "friend_shares: own delete" on public.friend_shares
  for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS ポリシー: sleep_records
-- 自分のレコード + 自分を friend_shares に追加した相手のレコード
-- ============================================================

drop policy if exists "sleep_records: select own or shared" on public.sleep_records;
create policy "sleep_records: select own or shared" on public.sleep_records
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from public.friend_shares fs
      where fs.user_id   = sleep_records.user_id  -- レコードオーナーが共有設定している
        and fs.friend_id = auth.uid()              -- 閲覧者が共有先
    )
  );

drop policy if exists "sleep_records: own insert" on public.sleep_records;
create policy "sleep_records: own insert" on public.sleep_records
  for insert with check (auth.uid() = user_id);

drop policy if exists "sleep_records: own update" on public.sleep_records;
create policy "sleep_records: own update" on public.sleep_records
  for update using (auth.uid() = user_id);

drop policy if exists "sleep_records: own delete" on public.sleep_records;
create policy "sleep_records: own delete" on public.sleep_records
  for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS ポリシー: sleep_goals
-- 自分の宣言 + accepted 友達の宣言は閲覧可
-- INSERT のみ許可（UPDATE・DELETE なし = 不変）
-- ============================================================

drop policy if exists "sleep_goals: select own or accepted friend" on public.sleep_goals;
create policy "sleep_goals: select own or accepted friend" on public.sleep_goals
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and (
          (f.requester_id = auth.uid() and f.addressee_id = sleep_goals.user_id)
          or (f.addressee_id = auth.uid() and f.requester_id = sleep_goals.user_id)
        )
    )
  );

drop policy if exists "sleep_goals: own insert" on public.sleep_goals;
create policy "sleep_goals: own insert" on public.sleep_goals
  for insert with check (auth.uid() = user_id);

-- UPDATE・DELETE ポリシーは意図的に作成しない（宣言は不変）
```

- **GOTCHA**: `drop policy if exists` を先に実行することで、冪等（何度実行しても安全）になっている。Supabase MCP 経由で実行する場合も同様。
- **VALIDATE**: SQL エディタで実行後、エラーなく完了すること

---

### Task 3: Supabase に SQL を適用する

MCP が接続済みの場合:
- Supabase MCP の `execute_sql` ツールで `001_initial_schema.sql` の内容を実行

MCP 未接続の場合:
- Supabase ダッシュボード → SQL Editor → New Query → 内容を貼り付けて実行

- **VALIDATE**: 実行後エラーがないこと

---

### Task 4: RLS 動作確認クエリを実行する

以下を Supabase SQL エディタで実行し、期待値通りであることを確認:

```sql
-- 1. テーブルが作成されているか確認
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('profiles','friendships','friend_shares','sleep_records','sleep_goals')
order by table_name;
-- 期待: 5行が返る

-- 2. RLS ポリシーの一覧確認
select tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
order by tablename, cmd;
-- 期待: 各テーブルに対応するポリシーが一覧表示される

-- 3. トリガーの確認
select trigger_name, event_manipulation, event_object_table
from information_schema.triggers
where trigger_name = 'on_auth_user_created';
-- 期待: 1行が返る

-- 4. unique constraint の確認
select conname, contype, conrelid::regclass
from pg_constraint
where conname in ('sleep_goals_unique_date', 'sleep_records_unique_date', 'friendships_unique')
order by conname;
-- 期待: 3行が返る
```

---

### Task 5: PRD の Phase 2 ステータスを `in-progress` → `complete` に更新する

- **ACTION**: `.claude/PRPs/prds/sleep-tracker.prd.md` の Phase 2 行を更新する
- **IMPLEMENT**:

```
変更前: | 2 | DB スキーマ & RLS | ... | pending | ...
変更後: | 2 | DB スキーマ & RLS | ... | complete | ...
```

また PRP Plan 列に `phase-02-db-schema-rls.plan.md` を追記する。

---

## Testing Strategy

### RLS ポリシーテスト (SQL エディタで手動実行)

```sql
-- テスト用ユーザーを Supabase Auth で2件作成してから実行
-- User A: <user_a_id>, User B: <user_b_id>

-- テスト 1: A は B の goals を見られないこと（friends でないため）
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "<user_a_id>"}';
select count(*) from sleep_goals where user_id = '<user_b_id>';
-- 期待: 0

-- テスト 2: 友達追加後は goals が見えること
-- (requester=A, addressee=B, status=accepted を挿入後)
select count(*) from sleep_goals where user_id = '<user_b_id>';
-- 期待: 1以上（テストデータを先に挿入しておく）

-- テスト 3: sleep_goals は UPDATE 不可
update sleep_goals set daily_goal = 'hacked' where user_id = '<user_a_id>';
-- 期待: 0 rows affected（UPDATE ポリシーがないため）
```

### Edge Cases Checklist

- [ ] 自分自身を友達申請しようとした場合 → `check (requester_id <> addressee_id)` で拒否
- [ ] 同じ日に sleep_goal を2回 INSERT → unique constraint で 2回目が拒否
- [ ] 同じ日に sleep_record を2回 INSERT → unique constraint で 2回目が拒否
- [ ] 未認証ユーザーが profiles を SELECT → RLS に `to authenticated` が付いているため 0件

---

## Validation Commands

### スキーマ確認

```sql
-- Supabase SQL エディタで実行
select table_name from information_schema.tables
where table_schema = 'public'
  and table_name in ('profiles','friendships','friend_shares','sleep_records','sleep_goals')
order by table_name;
```

EXPECT: 5行返る

### TypeScript 型整合チェック

```bash
# src/types/index.ts の型が既存スキーマと整合していることを確認
npx tsc --noEmit
```

EXPECT: エラー 0

---

## Acceptance Criteria

- [ ] `supabase/migrations/001_initial_schema.sql` が作成されている
- [ ] 全5テーブルが Supabase に存在する
- [ ] 各テーブルに RLS が有効で、ポリシーが設定されている
- [ ] `on_auth_user_created` トリガーが auth.users に設定されている
- [ ] `sleep_goals_unique_date` constraint が機能している（宣言の不変性）
- [ ] SQL エディタの確認クエリが全て期待値通り
- [ ] `npx tsc --noEmit` がエラー 0

## Completion Checklist

- [ ] SQL は冪等（`create if not exists` / `drop policy if exists` を使用）
- [ ] `security definer` トリガーに `set search_path = public` を設定
- [ ] UPDATE ポリシーを意図的に省略したテーブル（sleep_goals）は注記あり
- [ ] インデックスが高頻度クエリパスに対応している

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Supabase MCP 未認証で実行できない | LOW | MEDIUM | SQL エディタで手動実行にフォールバック |
| トリガーが Apple Sign In の metadata 形式と不一致 | MEDIUM | LOW | Phase 3 実装時にトリガーを検証・修正。username は Phase 9 で変更可能 |
| RLS ポリシーの論理ミスでデータ漏洩 | LOW | HIGH | Task 4 の確認クエリで必ずテスト |

## Notes

- `sleep_goals` に UPDATE/DELETE ポリシーを作成しないことで「宣言は不変」を DB レベルで強制している。これは PRD の決定事項（Decisions Log 参照）。
- `profiles` の SELECT は `to authenticated` スコープで全ユーザーに開放。これは Phase 7 の友達検索（ユーザー名検索）に必要。プライバシーが問題になるなら Phase 7 で検索専用 RPC に切り替える。
- タイムゾーン: `sleep_records.bedtime_at` / `wake_at` は `timestamptz`（UTC保存）。表示時のローカル変換は `src/lib/sleep.ts` の `formatLocalTime()` で処理済み。
