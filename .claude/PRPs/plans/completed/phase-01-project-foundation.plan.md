# Plan: Phase 1 — プロジェクト基盤セットアップ

## Summary

Expo SDK 54 の素のスキャフォールドに、Expo Router v4 ベースのタブナビゲーション骨格・全依存パッケージ・TypeScript パスエイリアス・Supabase クライアントスタブ・Zustand ストアスタブを追加する。後続フェーズ全員が依存するディレクトリ構成・型定義・コード規約を確立するフェーズ。

## User Story

As a developer,
I want a fully wired project foundation (router, packages, directory structure, stubs),
So that subsequent feature phases can implement without touching configuration.

## Problem → Solution

`App.tsx` + `index.ts` の素のスキャフォールド → Expo Router v4 でルーティング管理、タブ4本のナビゲーション骨格、`src/` 以下に全ドメインコードが整理された状態

## Metadata

- **Complexity**: Large
- **Source PRD**: `.claude/PRPs/prds/sleep-tracker.prd.md`
- **PRD Phase**: Phase 1 — プロジェクト基盤
- **Estimated Files**: 新規 18 + 変更 4 + 削除 2 = 24 操作

---

## UX Design

### Before

```
起動 → App.tsx のデフォルトテキスト「Open up App.tsx...」が表示されるだけ
```

### After

```
起動 → 4タブ表示（Today / History / Friends / Profile）
        ※ 認証ガードは Phase 3 で実装。Phase 1 では tabs が直接表示される
```

### Interaction Changes

| Touchpoint | Before | After | Notes |
|---|---|---|---|
| エントリポイント | `index.ts` (registerRootComponent) | `expo-router/entry` | package.json の main フィールド変更 |
| ルーティング | なし | Expo Router v4 ファイルベース | `app/` ディレクトリが URL ツリー |
| タブ | なし | Today / History / Friends / Profile | Ionicons アイコン付き |

---

## Mandatory Reading

| Priority | File | Lines | Why |
|---|---|---|---|
| P0 | `package.json` | all | main フィールドの変更箇所を確認 |
| P0 | `app.json` | all | scheme・plugins 追加箇所を確認 |
| P0 | `tsconfig.json` | all | paths 追加箇所を確認 |
| P1 | `.gitignore` | all | `.env` が除外されているか確認 |

## External Documentation

| Topic | Key Takeaway |
|---|---|
| Expo Router v4 | `"main": "expo-router/entry"` + `scheme` in app.json が必須。Expo Go では Apple Sign In 不可 |
| Supabase React Native | SecureStore adapter 必須。`detectSessionInUrl: false` を設定 |
| Expo Path Aliases | `baseUrl: "."` + `paths` in tsconfig.json のみで Metro が解決（babel 不要） |
| expo-build-properties | `useFrameworks: static` を iOS に設定しないと Supabase Realtime がビルド失敗する場合がある |
| react-native-url-polyfill | Supabase が依存する URL API のポリフィル。root layout の **最初の import** として必要 |

---

## Patterns to Mirror

このプロジェクトは新規のため、以下のパターンを「プロジェクト規約として確立」する。

### NAMING_CONVENTION
```
ディレクトリ:  kebab-case        (src/hooks/, src/lib/)
コンポーネント: PascalCase.tsx   (TodayScreen.tsx)
フック:        useXxx.ts         (useAuth.ts)
ストア:        xxxStore.ts       (authStore.ts)
型定義:        index.ts (src/types/ 以下に集約)
スクリーン:    app/(tabs)/xxx.tsx (Expo Router の規約に従う)
```

### COMPONENT_STYLE
```tsx
// StyleSheet.create を使用。インライン style オブジェクト禁止。
const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
})
```

### ERROR_HANDLING
```tsx
// unknown を受け取り Error に絞り込む
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message
  return 'エラーが発生しました'
}
```

### ZUSTAND_STORE
```ts
// create<State>() で型を明示。セッター関数は set を使う。
export const useXxxStore = create<XxxState>((set) => ({
  value: null,
  setValue: (v) => set({ value: v }),
}))
```

### EXPO_ROUTER_LAYOUT
```tsx
// 各 _layout.tsx は認証状態に応じて Redirect を返す
if (isLoading) return null
if (!session) return <Redirect href="/(auth)" />
return <Stack screenOptions={{ headerShown: false }} />
```

---

## Files to Change

| File | Action | 理由 |
|---|---|---|
| `package.json` | UPDATE | main を expo-router/entry に変更、type-check script 追加 |
| `app.json` | UPDATE | scheme・bundleIdentifier・plugins・supportsTablet 追加 |
| `tsconfig.json` | UPDATE | baseUrl・paths・include 追加 |
| `.gitignore` | UPDATE | `.env` を追加（現状 `.env*.local` のみ） |
| `App.tsx` | DELETE | expo-router/entry が代替 |
| `index.ts` | DELETE | expo-router/entry が代替 |
| `eas.json` | CREATE | EAS Build 設定 |
| `.env.example` | CREATE | 環境変数テンプレート |
| `src/types/index.ts` | CREATE | 全ドメイン型定義 |
| `src/lib/supabase.ts` | CREATE | Supabase クライアント（SecureStore adapter） |
| `src/lib/sleep.ts` | CREATE | 睡眠ドメインユーティリティ |
| `src/store/authStore.ts` | CREATE | Zustand 認証ストア |
| `src/hooks/useAuth.ts` | CREATE | 認証フック（Phase 3 で実装、型のみ） |
| `app/_layout.tsx` | CREATE | ルートレイアウト（QueryClient・SafeAreaProvider） |
| `app/(auth)/_layout.tsx` | CREATE | 認証グループレイアウト |
| `app/(auth)/index.tsx` | CREATE | サインイン画面スタブ |
| `app/(tabs)/_layout.tsx` | CREATE | タブバーレイアウト（4タブ） |
| `app/(tabs)/index.tsx` | CREATE | Today スクリーンスタブ |
| `app/(tabs)/history.tsx` | CREATE | History スクリーンスタブ |
| `app/(tabs)/friends.tsx` | CREATE | Friends スクリーンスタブ |
| `app/(tabs)/profile.tsx` | CREATE | Profile スクリーンスタブ |

## NOT Building

- 認証ロジック（Phase 3）
- Supabase クエリ（Phase 2 以降）
- 実際の UI コンポーネント（Phase 4 以降）
- テストセットアップ（Phase 3 以降）

---

## Step-by-Step Tasks

---

### Task 1: パッケージインストール

- **ACTION**: 以下のコマンドを順番に実行する
- **GOTCHA**: `npx expo install` は Expo SDK 54 に対応したバージョンを自動選択する。npm install に切り替えると不整合が起きる

```bash
# Expo 管理パッケージ（バージョン自動選択）
npx expo install \
  expo-router \
  react-native-safe-area-context \
  react-native-screens \
  expo-linking \
  expo-constants \
  expo-apple-authentication \
  expo-secure-store \
  expo-notifications \
  expo-dev-client \
  react-native-svg \
  react-native-linear-gradient \
  expo-build-properties

# 非 Expo パッケージ
npm install \
  @supabase/supabase-js \
  zustand \
  @tanstack/react-query \
  date-fns \
  react-native-gifted-charts \
  react-native-url-polyfill
```

- **VALIDATE**: `npm list expo-router` でバージョンが表示されること

---

### Task 2: package.json を更新

- **ACTION**: `"main"` フィールドを変更し、`type-check` スクリプトを追加する
- **IMPLEMENT**:

```json
{
  "name": "sleep-tracker",
  "version": "1.0.0",
  "main": "expo-router/entry",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "expo": "~54.0.33",
    "expo-status-bar": "~3.0.9",
    "react": "19.1.0",
    "react-native": "0.81.5"
  },
  "devDependencies": {
    "@types/react": "~19.1.0",
    "typescript": "~5.9.2"
  },
  "private": true
}
```

※ Task 1 のインストール後に `dependencies`/`devDependencies` は自動更新されるため、その内容を保持しつつ `main` と `scripts` のみ上記のように変更する。

- **VALIDATE**: `cat package.json | grep '"main"'` で `expo-router/entry` が表示されること

---

### Task 3: app.json を更新

- **ACTION**: scheme・bundleIdentifier・usesAppleSignIn・plugins を追加し、iOS専用設定に更新する
- **IMPLEMENT**:

```json
{
  "expo": {
    "name": "sleep-tracker",
    "slug": "sleep-tracker",
    "scheme": "sleeptracker",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "light",
    "newArchEnabled": true,
    "splash": {
      "image": "./assets/splash-icon.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "ios": {
      "supportsTablet": false,
      "bundleIdentifier": "com.sleeptracker.app",
      "usesAppleSignIn": true
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      }
    },
    "web": {
      "bundler": "metro"
    },
    "plugins": [
      "expo-router",
      "expo-apple-authentication",
      [
        "expo-notifications",
        {
          "icon": "./assets/icon.png",
          "color": "#ffffff"
        }
      ],
      [
        "expo-build-properties",
        {
          "ios": {
            "useFrameworks": "static"
          }
        }
      ]
    ]
  }
}
```

- **GOTCHA**: `"bundleIdentifier": "com.sleeptracker.app"` は Apple Developer Account の Bundle ID と一致させる必要がある。App Store 提出前に正式な Bundle ID に変更すること
- **VALIDATE**: `cat app.json | grep scheme` で `sleeptracker` が表示されること

---

### Task 4: tsconfig.json を更新

- **ACTION**: `baseUrl`・`paths`・`include` を追加する
- **IMPLEMENT**:

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": [
    "**/*.ts",
    "**/*.tsx",
    ".expo/types/**/*.d.ts",
    "expo-env.d.ts"
  ]
}
```

- **GOTCHA**: `@/*` が `src/*` に解決される。`@/lib/supabase` → `src/lib/supabase.ts`。Expo SDK 50+ では Metro が tsconfig paths を自動で解決するため babel-plugin-module-resolver は不要
- **VALIDATE**: `npm run type-check` がパスすること（ファイル作成後）

---

### Task 5: .gitignore を更新

- **ACTION**: `.env` を追加する（現状は `.env*.local` のみ）
- **IMPLEMENT**: `.gitignore` の `# local env files` セクションに追記:

```
# local env files
.env
.env*.local
```

- **VALIDATE**: `cat .gitignore | grep "^\.env$"` で `.env` が表示されること

---

### Task 6: eas.json を作成

- **ACTION**: `.claude/PRPs/plans/` ではなくプロジェクトルートに `eas.json` を作成する
- **IMPLEMENT**: ファイルパス `eas.json`

```json
{
  "cli": {
    "version": ">= 12.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": true
      }
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {}
  }
}
```

- **VALIDATE**: `cat eas.json | grep developmentClient` で `true` が表示されること

---

### Task 7: .env.example を作成

- **ACTION**: プロジェクトルートに `.env.example` を作成する
- **IMPLEMENT**: ファイルパス `.env.example`

```
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
```

- **NOTE**: ユーザーはこのファイルを `.env` にコピーし、Supabase プロジェクトの実際の値を入力する必要がある
- **VALIDATE**: ファイルが存在すること

---

### Task 8: App.tsx と index.ts を削除

- **ACTION**: 2ファイルを削除する。expo-router/entry がこれらの役割を引き継ぐ
- **IMPLEMENT**:

```bash
rm App.tsx index.ts
```

- **VALIDATE**: `ls *.tsx *.ts 2>/dev/null` で両ファイルが存在しないこと

---

### Task 9: src/types/index.ts を作成

- **ACTION**: 全フェーズで使う共通型定義を作成する
- **IMPLEMENT**: ファイルパス `src/types/index.ts`

```typescript
export type FriendshipStatus = 'pending' | 'accepted'
export type RecordMethod = 'now' | 'manual'

export interface Profile {
  id: string
  username: string
  display_name: string | null
  push_token: string | null
  created_at: string
}

export interface Friendship {
  id: string
  requester_id: string
  addressee_id: string
  status: FriendshipStatus
  created_at: string
}

export interface FriendShare {
  user_id: string
  friend_id: string
  created_at: string
}

export interface SleepRecord {
  id: string
  user_id: string
  date: string             // 'YYYY-MM-DD' — 起床した日付
  bedtime_at: string | null  // ISO 8601 UTC
  bedtime_method: RecordMethod | null
  wake_at: string | null     // ISO 8601 UTC
  wake_method: RecordMethod | null
  created_at: string
}

export interface SleepGoal {
  id: string
  user_id: string
  target_date: string       // 'YYYY-MM-DD'
  target_bedtime: string    // 'HH:MM:SS'
  target_wake_time: string  // 'HH:MM:SS'
  daily_goal: string | null
  created_at: string
}

// 友達タブ用: 友達の目標と達成状況
export interface FriendSleepView {
  profile: Profile
  is_shared: boolean  // 自分が friend_shares でお気に入り登録しているか
  goal: SleepGoal | null
  record: Pick<SleepRecord, 'date' | 'bedtime_at' | 'wake_at'> | null
  achieved: boolean | null
}
```

- **VALIDATE**: `npm run type-check` でエラーなし

---

### Task 10: src/lib/supabase.ts を作成

- **ACTION**: Supabase クライアントを SecureStore adapter で初期化する
- **IMPLEMENT**: ファイルパス `src/lib/supabase.ts`
- **GOTCHA**: `EXPO_PUBLIC_` プレフィックスが必須。これがないと Expo のバンドラがクライアントに env var を含めない

```typescript
import * as SecureStore from 'expo-secure-store'
import { createClient } from '@supabase/supabase-js'

const ExpoSecureStoreAdapter = {
  getItem: (key: string) => SecureStore.getItemAsync(key),
  setItem: (key: string, value: string) => SecureStore.setItemAsync(key, value),
  removeItem: (key: string) => SecureStore.deleteItemAsync(key),
}

export const supabase = createClient(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      storage: ExpoSecureStoreAdapter,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  }
)
```

- **VALIDATE**: `npm run type-check` でエラーなし

---

### Task 11: src/lib/sleep.ts を作成

- **ACTION**: 睡眠ドメインのユーティリティ関数を作成する
- **IMPLEMENT**: ファイルパス `src/lib/sleep.ts`
- **GOTCHA**: `date` は「起床した日付」で統一する。23:00就寝→翌07:00起床なら date = 翌日

```typescript
import { format, parseISO, addDays } from 'date-fns'

export function getTodayDate(): string {
  return format(new Date(), 'yyyy-MM-dd')
}

export function getTomorrowDate(): string {
  return format(addDays(new Date(), 1), 'yyyy-MM-dd')
}

// ISOタイムスタンプをローカル時刻の HH:mm 形式に変換
export function formatLocalTime(isoString: string): string {
  return format(parseISO(isoString), 'HH:mm')
}

// time 型 ('HH:MM:SS') を表示用 'HH:mm' に変換
export function formatTimeField(timeString: string): string {
  return timeString.slice(0, 5)
}

// 睡眠時間を時間単位で計算
export function calcSleepDurationHours(bedtimeAt: string, wakeAt: string): number {
  return (parseISO(wakeAt).getTime() - parseISO(bedtimeAt).getTime()) / 3_600_000
}

// 達成判定: 目標時刻 ±30分以内を「達成」とする
export function isGoalAchieved(
  targetTime: string,   // 'HH:MM:SS'
  actualAt: string,     // ISO UTC
  targetDate: string    // 'YYYY-MM-DD' (目標の日付)
): boolean {
  const [h, m] = targetTime.split(':').map(Number)
  const targetDate_ = parseISO(targetDate)
  targetDate_.setHours(h, m, 0, 0)
  const diff = Math.abs(parseISO(actualAt).getTime() - targetDate_.getTime())
  return diff <= 30 * 60 * 1000
}
```

- **VALIDATE**: `npm run type-check` でエラーなし

---

### Task 12: src/store/authStore.ts を作成

- **ACTION**: Zustand で認証状態を管理するストアを作成する
- **IMPLEMENT**: ファイルパス `src/store/authStore.ts`
- **MIRROR**: ZUSTAND_STORE パターン

```typescript
import { create } from 'zustand'
import type { Session, User } from '@supabase/supabase-js'

interface AuthState {
  session: Session | null
  user: User | null
  isLoading: boolean
  setSession: (session: Session | null) => void
}

export const useAuthStore = create<AuthState>((set) => ({
  session: null,
  user: null,
  isLoading: true,
  setSession: (session) =>
    set({ session, user: session?.user ?? null, isLoading: false }),
}))
```

- **VALIDATE**: `npm run type-check` でエラーなし

---

### Task 13: src/hooks/useAuth.ts を作成（スタブ）

- **ACTION**: Phase 3 で実装する useAuth の型シグネチャのみ定義するスタブを作成する
- **IMPLEMENT**: ファイルパス `src/hooks/useAuth.ts`

```typescript
import { useAuthStore } from '@/store/authStore'

// signInWithApple・signOut の実装は Phase 3 で追加する
export function useAuth() {
  const { session, user, isLoading } = useAuthStore()

  async function signInWithApple(): Promise<void> {
    throw new Error('Phase 3 で実装予定')
  }

  async function signOut(): Promise<void> {
    throw new Error('Phase 3 で実装予定')
  }

  return { session, user, isLoading, signInWithApple, signOut }
}
```

- **VALIDATE**: `npm run type-check` でエラーなし

---

### Task 14: app/_layout.tsx を作成

- **ACTION**: ルートレイアウトを作成する。Supabase のセッション変化を監視し authStore に反映する
- **IMPLEMENT**: ファイルパス `app/_layout.tsx`
- **GOTCHA**: `import 'react-native-url-polyfill/auto'` はこのファイルの **最初の import** でなければならない。Supabase の URL パースが依存している

```tsx
import 'react-native-url-polyfill/auto'
import { useEffect } from 'react'
import { Stack } from 'expo-router'
import { SafeAreaProvider } from 'react-native-safe-area-context'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/store/authStore'

const queryClient = new QueryClient()

export default function RootLayout() {
  const setSession = useAuthStore((s) => s.setSession)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
    })

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })

    return () => subscription.unsubscribe()
  }, [setSession])

  return (
    <SafeAreaProvider>
      <QueryClientProvider client={queryClient}>
        <Stack screenOptions={{ headerShown: false }} />
      </QueryClientProvider>
    </SafeAreaProvider>
  )
}
```

- **VALIDATE**: `npm run type-check` でエラーなし

---

### Task 15: app/(auth)/_layout.tsx を作成

- **ACTION**: 認証グループのレイアウトを作成する。ログイン済みなら tabs へリダイレクト
- **IMPLEMENT**: ファイルパス `app/(auth)/_layout.tsx`
- **MIRROR**: EXPO_ROUTER_LAYOUT パターン

```tsx
import { Redirect, Stack } from 'expo-router'
import { useAuthStore } from '@/store/authStore'

export default function AuthLayout() {
  const { session, isLoading } = useAuthStore()

  if (isLoading) return null
  if (session) return <Redirect href="/(tabs)" />

  return <Stack screenOptions={{ headerShown: false }} />
}
```

- **VALIDATE**: `npm run type-check` でエラーなし

---

### Task 16: app/(auth)/index.tsx を作成（スタブ）

- **ACTION**: サインイン画面のスタブを作成する。Phase 3 で Apple Sign In ボタンを実装する
- **IMPLEMENT**: ファイルパス `app/(auth)/index.tsx`

```tsx
import { View, Text, StyleSheet } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'

export default function SignInScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Sleep Tracker</Text>
      <Text style={styles.subtitle}>Phase 3 で Apple Sign In を実装</Text>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 32,
    fontWeight: '700',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: '#999',
  },
})
```

- **VALIDATE**: `npm run type-check` でエラーなし

---

### Task 17: app/(tabs)/_layout.tsx を作成

- **ACTION**: 4タブのレイアウトを作成する。未認証なら auth へリダイレクト
- **IMPLEMENT**: ファイルパス `app/(tabs)/_layout.tsx`
- **MIRROR**: EXPO_ROUTER_LAYOUT パターン

```tsx
import { Redirect, Tabs } from 'expo-router'
import { Ionicons } from '@expo/vector-icons'
import { useAuthStore } from '@/store/authStore'

export default function TabLayout() {
  const { session, isLoading } = useAuthStore()

  if (isLoading) return null
  if (!session) return <Redirect href="/(auth)" />

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#1a1a2e',
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Today',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="moon-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="history"
        options={{
          title: 'History',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="bar-chart-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="friends"
        options={{
          title: 'Friends',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="people-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="person-outline" size={size} color={color} />
          ),
        }}
      />
    </Tabs>
  )
}
```

- **VALIDATE**: `npm run type-check` でエラーなし

---

### Task 18: app/(tabs)/index.tsx を作成（スタブ）

- **IMPLEMENT**: ファイルパス `app/(tabs)/index.tsx`

```tsx
import { ScrollView, Text, StyleSheet } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'

export default function TodayScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.heading}>Today</Text>
        <Text style={styles.placeholder}>Phase 4・5 で睡眠記録と目標宣言を実装</Text>
      </ScrollView>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { padding: 20 },
  heading: { fontSize: 28, fontWeight: '700', marginBottom: 8 },
  placeholder: { fontSize: 14, color: '#999' },
})
```

---

### Task 19: app/(tabs)/history.tsx を作成（スタブ）

- **IMPLEMENT**: ファイルパス `app/(tabs)/history.tsx`

```tsx
import { View, Text, StyleSheet } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'

export default function HistoryScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.heading}>History</Text>
        <Text style={styles.placeholder}>Phase 6 で履歴グラフを実装</Text>
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { padding: 20 },
  heading: { fontSize: 28, fontWeight: '700', marginBottom: 8 },
  placeholder: { fontSize: 14, color: '#999' },
})
```

---

### Task 20: app/(tabs)/friends.tsx を作成（スタブ）

- **IMPLEMENT**: ファイルパス `app/(tabs)/friends.tsx`

```tsx
import { View, Text, StyleSheet } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'

export default function FriendsScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.heading}>Friends</Text>
        <Text style={styles.placeholder}>Phase 7 で友達機能を実装</Text>
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { padding: 20 },
  heading: { fontSize: 28, fontWeight: '700', marginBottom: 8 },
  placeholder: { fontSize: 14, color: '#999' },
})
```

---

### Task 21: app/(tabs)/profile.tsx を作成（スタブ）

- **IMPLEMENT**: ファイルパス `app/(tabs)/profile.tsx`

```tsx
import { View, Text, StyleSheet } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'

export default function ProfileScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.heading}>Profile</Text>
        <Text style={styles.placeholder}>Phase 9 で設定・サインアウトを実装</Text>
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { padding: 20 },
  heading: { fontSize: 28, fontWeight: '700', marginBottom: 8 },
  placeholder: { fontSize: 14, color: '#999' },
})
```

---

## Validation Commands

### Static Analysis

```bash
npm run type-check
```

EXPECT: Zero type errors

### 起動確認（要 .env 作成）

```bash
# .env.example を .env にコピーし、Supabase の値を入力してから実行
cp .env.example .env
# .env を編集して実際の SUPABASE_URL と SUPABASE_ANON_KEY を入力

npm run ios
```

EXPECT: iOS シミュレータで 4タブ（Today / History / Friends / Profile）が表示される

### 開発ビルド（Apple Sign In が必要になる Phase 3 以降で実施）

```bash
npx eas build --profile development --platform ios
```

EXPECT: EAS Build が完了し、dev client が端末/シミュレータにインストールされる

### Manual Validation

- [ ] `npm run type-check` がエラー 0 で通過する
- [ ] iOS シミュレータで 4タブが表示される
- [ ] 各タブタップで画面が切り替わる
- [ ] `App.tsx` と `index.ts` が存在しない
- [ ] `.env` が `.gitignore` に含まれている（誤コミット防止）

---

## Acceptance Criteria

- [ ] Task 1〜21 が全て完了している
- [ ] `npm run type-check` が通過する
- [ ] iOS シミュレータで 4タブが表示・動作する
- [ ] `App.tsx`・`index.ts` が削除されている
- [ ] `@/lib/supabase` のパスエイリアスが TypeScript で解決できる
- [ ] `.env` が gitignore されている

## Completion Checklist

- [ ] `"main": "expo-router/entry"` に変更済み
- [ ] `app.json` に `scheme: "sleeptracker"` が設定済み
- [ ] `tsconfig.json` に `@/*` → `src/*` のパスエイリアスが設定済み
- [ ] `react-native-url-polyfill/auto` が `app/_layout.tsx` の最初の import になっている
- [ ] 全スタブ画面が `StyleSheet.create` を使用している（インライン style オブジェクトなし）
- [ ] `.env.example` がコミットされ `.env` がコミットされていない

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `expo install` でバージョン競合 | LOW | MEDIUM | エラーが出たら `npx expo install --fix` を実行 |
| パスエイリアスが Metro で解決されない | LOW | HIGH | `npx expo start --clear` でキャッシュクリア |
| `useFrameworks: static` による既存ライブラリ競合 | LOW | HIGH | EAS Build エラー時は expo-build-properties を除外して切り分け |

## Notes

**開発フロー（Phase 3 以降）**:
Expo Go では Apple Sign In が動作しないため、Phase 3 以降は `npx eas build --profile development --platform ios` でビルドした dev client を使う。現 Phase 1 では `npm run ios`（Expo Go）でタブ確認まで可能。

**bundleIdentifier について**:
`com.sleeptracker.app` はプレースホルダー。App Store 提出前に Apple Developer Account の Bundle ID と一致する値に変更する。
