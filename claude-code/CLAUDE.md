# User-Level CLAUDE.md

## SHOULD: モード管理

以下の条件に該当するタスクでは、作業前に `EnterPlanMode` を使用してplanモードへの移行を提案すること：

- 3ファイル以上にまたがる変更が予想される
- 新機能の追加・大規模リファクタリング
- 要件が曖昧で調査フェーズが必要な場合
- 複数の実装アプローチが考えられる場合

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
