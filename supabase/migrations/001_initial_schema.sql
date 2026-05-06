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
