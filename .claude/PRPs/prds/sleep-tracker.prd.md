# Sleep Tracker — Social Sleep Accountability App

## Problem Statement

睡眠習慣を改善したいと思っている若者が、個人だけでは三日坊主になりやすく継続できない。既存の睡眠アプリはデータ計測に特化しており、「他者への宣言」という社会的アカウンタビリティを活用する仕組みがない。この問題を放置すると、ユーザーは習慣形成を諦め、長期的な生活の質を損ない続ける。

## Evidence

- HabitShare の調査: 他者に進捗を公開することで習慣達成率が 65% 向上
- 睡眠 × 宣言 × 応援 の組み合わせを持つアプリは市場に存在しない（競合調査より）
- BeReal は「毎日の社会的儀式」によって習慣ループを形成し 2.3 億ユーザーを獲得
- 睡眠習慣アプリの 70% が 100 日以内に離脱 — 原因は「他者の目がなく今日はいいかになる」

## Proposed Solution

翌日の目標就寝・起床時刻と一言目標を友達に「宣言」し、実際の睡眠時間を記録して達成状況を共有するiOSアプリ。競争ではなく応援ベースの設計とし、宣言の公開範囲はプライバシー設定で制御できる。広告収益モデルで無料提供する。

## Key Hypothesis

宣言機能と友達への達成共有 が 翌日を意識した睡眠行動の変化 を 生活リズムを整えたい若者 に対してもたらす。
我々が正しいと分かる時: **3ヶ月以内に 100 ダウンロード達成**、および**月間広告収益の発生**。

## What We're NOT Building

- 睡眠の質分析（心拍・いびき検知など）— ハードウェア連携は別フェーズ
- グループ・コミュニティ機能 — 友達以外への公開フィードは今回対象外
- Android版 — 初期はiOSのみで検証
- 宣言の変更機能 — 不変とすることで「真剣な一日一回の儀式」を演出する

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|--------------|
| ダウンロード数 | 100（3ヶ月以内） | App Store Connect |
| 広告収益 | 月間発生（金額問わず） | AdMob ダッシュボード |
| D7リテンション | 30%以上 | Analytics |
| 宣言実行率 | DAUの50%以上が翌日目標を宣言 | Supabase クエリ |

## Open Questions

- [ ] 友達が少ない初期ユーザーへの体験設計（フォールバックが必要か）
- [ ] 広告フォーマット: バナー vs インタースティシャル（UX との兼ね合い）
- [ ] Apple 審査: 通知の説明文が審査で引っかかる可能性（要確認）
- [ ] 宣言した目標の「達成判定ロジック」の定義（目標時刻 ±30分以内？）

---

## Users & Context

**Primary User**
- **Who**: 10〜30代、生活リズムが乱れていることを自覚しているが一人では改善できない人。LINEやInstagramでつながりがある友人グループを持つ。
- **Current behavior**: 特に就寝時刻を意識せずスマホをだらだら触って気づいたら深夜になっている
- **Trigger**: 翌日に大事な予定がある夜、または友達がアプリを使い始めたのを知った時
- **Success state**: 毎晩宣言することが「夜の儀式」になり、友達と生活リズムを揃えていく感覚が得られる

**Job to Be Done**
生活リズムを整えたいと思っているとき、翌日の就寝・起床目標を友達に宣言したい、そうすれば一人では続かない習慣を社会的なつながりの力で継続できる。

**Non-Users**
睡眠データを医療・アスリート用途で分析したい人（ Whoop や Oura のユーザー層）。本アプリは習慣形成が目的であり、精密データ計測は提供しない。

---

## Solution Detail

### Core Capabilities (MoSCoW)

| Priority | Capability | Rationale |
|----------|------------|-----------|
| Must | 就寝・起床時刻の記録（now/manual + ラベル） | コア価値の基盤 |
| Must | 翌日の目標宣言（不変、1回のみ） | 差別化機能 |
| Must | 友達への目標・達成状況の共有 | 社会的アカウンタビリティの核 |
| Must | Apple Sign In 認証 | App Store 必須要件 |
| Should | 睡眠履歴グラフ（14日間・達成率） | 自己モニタリングによる継続動機 |
| Should | プッシュ通知（目標時刻リマインダー） | 習慣ループのトリガー形成 |
| Should | お気に入り友達への実際の記録公開 | プライバシー配慮型の深い共有 |
| Could | 一言目標（任意テキスト） | 宣言に文脈を加える |
| Could | 広告（AdMob バナー） | 収益化 |
| Won't | 睡眠スコア・分析 | スコープ外 |
| Won't | グループ・コミュニティフィード | スコープ外 |

### MVP Scope

全機能を v1 として含む（ユーザーの判断）。ただし実装優先度は上記 MoSCoW 順に従う。

### User Flow（クリティカルパス）

```
起動 → Apple Sign In → プロフィール設定（ユーザー名）
  → 今日タブ
      [今日の記録]
        → 「今記録する」タップ → 現在時刻セット（now ラベル）
          OR 時刻ピッカーで手動入力（manual ラベル）
      [翌日の目標宣言]
        → 目標就寝・起床時刻を設定 → 任意テキスト目標 → 宣言（以降ロック）
  → 友達タブ
      → ユーザー名で検索 → リクエスト送信 → 承認
      → 友達の翌日目標・達成状況を閲覧
      → お気に入り設定 → 実際の記録も公開
```

---

## Technical Approach

**Feasibility**: HIGH

**Architecture Notes**
- **Expo SDK 54 + React Native 0.81.5** (New Architecture 有効) — 既存プロジェクトに準拠
- **Expo Router v4** — ファイルベースルーティング、タブ3本構成
- **Supabase Auth + Apple Sign In** — App Store 審査要件を満たす最小構成
- **Supabase PostgreSQL + RLS** — 友達機能のアクセス制御を DB 層で実装
- **friend_shares テーブル** — 「お気に入り = 実記録を共有する相手」をセパレートテーブルで管理
- **Zustand + TanStack Query** — クライアント状態 / サーバー状態の分離
- **expo-notifications** — ローカルスケジュール通知（目標時刻リマインダー）
- **react-native-gifted-charts + react-native-svg** — 履歴グラフ

**DBスキーマ概要**

```
profiles         (id, username, display_name, push_token)
friendships      (requester_id, addressee_id, status: pending|accepted)
friend_shares    (user_id → sharing with → friend_id) ← お気に入り実装
sleep_records    (user_id, date, bedtime_at, bedtime_method, wake_at, wake_method)
sleep_goals      (user_id, target_date, target_bedtime, target_wake_time, daily_goal)
                 ※ unique(user_id, target_date) で不変を強制
```

**Technical Risks**

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Apple Sign In の Bundle ID / Team ID 設定ミス | HIGH | Phase 3 完了後に実機で最初に動作確認 |
| Supabase RLS 設定ミス（他人データ漏洩） | HIGH | Phase 2 完了後に RLS テストを必須化 |
| expo-notifications 権限 UI で審査リジェクト | MEDIUM | 「なぜ通知が必要か」説明画面を権限リクエスト前に挿入 |
| react-native-gifted-charts の New Architecture 非対応 | LOW | victory-native を代替候補として確保 |
| 日付またがり処理（23:00就寝→翌07:00起床） | MEDIUM | date-fns で getSleepDate() ユーティリティを一元化 |

---

## Implementation Phases

| # | Phase | Description | Status | Parallel | Depends | PRP Plan |
|---|-------|-------------|--------|----------|---------|----------|
| 1 | プロジェクト基盤 | Expo Router, パッケージ導入, ディレクトリ構成, eas.json | in-progress | - | - | `.claude/PRPs/plans/phase-01-project-foundation.plan.md` |
| 2 | DB スキーマ & RLS | Supabase マイグレーション SQL + RLS ポリシー | pending | - | 1 | - |
| 3 | 認証 | Apple Sign In + Supabase Auth + ルートガード | pending | - | 2 | - |
| 4 | 睡眠記録機能 | 今日の就寝・起床記録（now/manual ラベル） | pending | with 5 | 3 | - |
| 5 | 翌日目標宣言機能 | 目標時刻・テキスト宣言 + 不変ロック UI | pending | with 4 | 3 | - |
| 6 | 履歴タブ | 14日グラフ + 達成率 + カレンダービュー | pending | with 7 | 4,5 | - |
| 7 | 友達機能 | 検索・リクエスト・お気に入り・プライバシー制御 | pending | with 6 | 3 | - |
| 8 | プッシュ通知 | 目標時刻リマインダーのスケジュール登録 | pending | - | 4,5 | - |
| 9 | プロフィール・設定 | ユーザー名変更・通知設定・ログアウト | pending | with 8 | 3 | - |
| 10 | 広告 + App Store 提出 | AdMob 統合 + EAS Production Build + 審査提出 | pending | - | 1〜9 | - |

### Phase Details

**Phase 1: プロジェクト基盤**
- **Goal**: Expo Router v4 が動作し、タブナビゲーションの骨格が完成している
- **Scope**: パッケージインストール、app.json 更新、`src/` ディレクトリ構成、タブスクリーンスタブ、.env.example、eas.json
- **Success signal**: `npm run ios` でシミュレータ上にタブが3本表示される

**Phase 2: DBスキーマ & RLS**
- **Goal**: Supabase に全テーブルが作成され、RLS により自分のデータのみ操作可能、友達ポリシーが正しく動作している
- **Scope**: `supabase/migrations/001_initial_schema.sql`、RLS ポリシー、Auth トリガー（profile 自動生成）
- **Success signal**: Supabase SQL エディタでポリシーテストが通過

**Phase 3: 認証**
- **Goal**: Apple Sign In でサインイン・サインアウトでき、未認証時はログイン画面にリダイレクトされる
- **Scope**: `expo-apple-authentication`、Supabase Auth 連携、`expo-secure-store` トークン永続化、Zustand authStore
- **Success signal**: 実機でApple Sign In が完了し、セッションが再起動後も保持される

**Phase 4: 睡眠記録機能**
- **Goal**: 今日の就寝・起床時刻を「今記録する」または手動入力で記録でき、Supabase に保存される
- **Scope**: Today スクリーン、DateTimePicker、now/manual ラベル、sleep_records CRUD
- **Success signal**: 記録がSupabaseに保存され、今日タブに表示される

**Phase 5: 翌日目標宣言機能**
- **Goal**: 翌日の就寝・起床目標と任意テキストを宣言でき、宣言後はロックされ変更できない
- **Scope**: Today スクリーン内の宣言 UI、sleep_goals INSERT（UPDATE 不可）、ロック状態表示
- **Success signal**: 宣言後にUIが read-only になり、Supabase unique constraint でダブル宣言が弾かれる

**Phase 6: 履歴タブ**
- **Goal**: 直近14日間の睡眠グラフと目標達成率が表示される
- **Scope**: react-native-gifted-charts 棒グラフ、カレンダービュー、達成判定ロジック（±30分）
- **Success signal**: グラフに14日分のデータが表示され、達成日がカレンダーで確認できる

**Phase 7: 友達機能**
- **Goal**: ユーザー名で友達を検索・追加でき、友達の翌日目標と達成状況が見える。お気に入りの相手には実際の記録も公開される
- **Scope**: 友達検索・リクエスト・承認 UI、friend_shares テーブル操作、友達カードコンポーネント（2種類の表示）
- **Success signal**: A → B に友達申請し承認後、A の友達タブに B の宣言が表示される。B がAをお気に入りにすると A は B の実際の記録も見える

**Phase 8: プッシュ通知**
- **Goal**: 宣言した目標時刻の30分前にリマインダーが届く
- **Scope**: expo-notifications 権限フロー、ローカル通知スケジュール、目標宣言時に通知を自動登録・更新
- **Success signal**: 実機で宣言後、指定時刻に通知が届く

**Phase 9: プロフィール・設定**
- **Goal**: ユーザー名変更、通知ON/OFF、サインアウトができる
- **Scope**: Profile タブ実装
- **Success signal**: ユーザー名変更が即時反映され、サインアウトでログイン画面に戻る

**Phase 10: 広告 + App Store 提出**
- **Goal**: AdMob バナーが表示され、App Store 審査に提出される
- **Scope**: react-native-google-mobile-ads 統合、EAS production build、App Store Connect 設定
- **Success signal**: TestFlight でバナー広告が表示され、審査提出が完了する

### Parallelism Notes

- **Phase 4 & 5 は並列可能**: どちらも Phase 3（認証）完了後に独立して進められる
- **Phase 6 & 7 は並列可能**: Phase 4/5 の Supabase スキーマが完成していれば同時進行できる
- **Phase 8 & 9 は並列可能**: どちらも Phase 5（目標宣言）完了後に独立して進められる

---

## Decisions Log

| Decision | Choice | Alternatives | Rationale |
|----------|--------|--------------|-----------|
| 認証方式 | Apple Sign In のみ | Google OAuth + Apple Sign In | App Store 要件を満たしつつ実装をシンプルに。Android 非対応なので Google 不要 |
| ルーティング | Expo Router v4 | React Navigation | Expo 54 標準、設定量が少ない |
| 状態管理 | Zustand + TanStack Query | Redux, SWR | 軽量・TypeScript 相性が良く、サーバー/クライアント状態を明確に分離できる |
| 宣言の不変性 | DB の unique constraint で強制 | アプリ側でのみ制御 | DB レベルで保証することでバグ・不正操作を排除 |
| お気に入り実装 | friend_shares テーブル分離 | friendships テーブルにカラム追加 | 「自分が誰に見せるか」という意図が明確になり、RLS ポリシーが書きやすい |
| グラフライブラリ | react-native-gifted-charts | victory-native | New Architecture 対応、軽量。問題時は victory-native に切替 |
| 日時保存形式 | UTC timestamptz（表示時にローカル変換） | ローカル時刻で保存 | タイムゾーン問題を根本から排除 |

---

## Research Summary

**Market Context**
- 睡眠 × 宣言 × 応援 の組み合わせは市場に存在せず、明確なギャップがある
- 競合は Sleepover（競争型）のみ。応援型の非競争設計は差別化ポイントになる
- HabitShare の実績: 他者への公開で達成率 65% 向上。アカウンタビリティの有効性は実証済み
- 離脱防止の鍵: 低ペナルティ設計（宣言できなくても罰しない）+ 毎日の小さな儀式
- 収益化: 初期は広告（AdMob）、規模が出たらフリーミアム or 友達招待でプレミアム解放も検討

**Technical Context**
- プロジェクトは Expo SDK 54 のスキャフォールドのみ。全実装がこれから
- Supabase + Apple Sign In + Expo の組み合わせは実績が多く、ドキュメントが整備されている
- New Architecture 有効のため、使用するライブラリの互換性確認が必要（特にグラフ系）
- EAS Build が Apple Sign In と App Store 提出に必須（Expo Go では動作不可）

---

*Generated: 2026-05-05*
*Status: DRAFT - 達成判定ロジック（±30分の定義）は実装前に最終確認が必要*
