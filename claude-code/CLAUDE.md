# User-Level CLAUDE.md

## MUST: コミュニケーション規約

**必ず日本語でやり取り**

## MUST: 絶対にコミットしない・Claude等のAIが読み込まないもの

- API keys
- パスワード
- 秘密鍵
- `.env`ファイル

## MUST: 作業方針

**基本PLANモードで開始すること**

原則としてPLANモードで方針を設計・提案し、承認を得てから実装を開始する

**PLANモードの除外**

ユーザーが以下のようなキーワードを含める場合は、PLANモードをスキップして直接実装してよい:

- 「直接実装して」
- 「すぐに実装して」
- 「PLANモード不要」
- 「計画不要」

## SHOULD: Git規約(プロジェクトで上書き可)

### コミットメッセージ

**Conventional Commits**形式を推奨:

```txt
<type>(<scope>): <subject>

<body>

<footer>
```

**Type:**

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント変更
- `style`: デザイン修正
- `refactor`: リファクタリング
- `perf`: パフォーマンス改善
- `test`: テスト追加・修正
- `chore`: ビルドプロセスやツール変更
