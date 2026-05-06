# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS向け睡眠管理アプリ。起床・就寝時間の記録、翌日の目標起床・就寝時間の宣言、翌日の目標（任意1件）の宣言ができる。

TypeScript strict mode, React 19, React Native 0.81.5, Expo ~54。New Architecture (`newArchEnabled: true`) 有効。縦向き固定、ライトUIスタイル。ターゲットはiOSのみ。

## git
git@github.com:Jo042/sleep-tracker.gitがリポジトリです。
`gh`コマンドを使用して進めてください。


## commit message
"feat: 新しい機能"
"fix: バグの修正"
"docs: ドキュメントのみの変更"
"style: 空白、フォーマット、セミコロン追加など"
"refactor: 仕様に影響がないコード改善(リファクタ)"
"perf: パフォーマンス向上関連"
"test: テスト関連"
"chore: ビルド、補助ツール、ライブラリ関連"

## git work flow
1.`prefix/内容`でブランチ作成
2. 実装
3. 適切な粒度でcommit
4. PR作成
5. review
6. マージ


## Commands

```bash
# Start dev server (choose platform interactively)
npm start

# Target a specific platform
npm run ios
npm run android
npm run web

# Type check
npx tsc --noEmit
```

No test runner is configured yet. No lint config yet.

## Architecture

Currently scaffold only — `App.tsx` is the single root component, registered via `index.ts` using `registerRootComponent`.

As the app grows, structure by feature under `src/`:

```
src/
├── components/     # Shared UI components
├── screens/        # Full-screen views
├── hooks/          # Custom React hooks
├── lib/            # Pure utilities (date math, sleep score logic)
├── store/          # Client state (Zustand or similar)
└── types/          # Shared TypeScript types
```

Sleep domain logic (bedtime calculation, duration, sleep quality scoring) belongs in `src/lib/`, not in components.

## Tech Stack

- **認証**: Supabase Auth（Google OAuth）
- **DB**: Supabase（PostgreSQL）
- **クライアント状態管理**: 未定（Zustandを想定）
- **ホスティング**: 未定

## Features

1. 起床・就寝時間の記録（毎日）
2. 翌日の目標起床・就寝時間の宣言
3. 翌日の目標宣言（任意、1件まで）

## Key Conventions

- `app.json` controls Expo config (icon, splash, orientation, Android edge-to-edge). Do not duplicate config in code.
- Use `StyleSheet.create` for styles; avoid inline style objects in JSX.
- New Architecture is enabled — avoid legacy modules that require the bridge.
- `tsconfig.json` extends `expo/tsconfig.base` with `strict: true`. Keep strict mode on.
