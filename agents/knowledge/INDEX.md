# ナレッジ索引（shared・公開）

<!--
  1トピック1行。「いつ読むか」のトリガーを必ず書く。書名だけでは呼び出されない。
  本文を書き換えてもこの索引が変わらないよう、行はトリガー中心に書くこと
  （索引が変わると次セッションのプロンプトキャッシュがミスするため）。
  実体: dotfiles/agents/knowledge/
-->

- [エージェントの指示ファイル読み込み仕様](agent-instruction-loading.md) —
  CLAUDE.md / AGENTS.md / rules / skills / settings / auto memory の置き場やロード順を扱うとき。
  モノレポでサブディレクトリから起動する構成を設計するとき。
  このナレッジ基盤そのものを変更するとき
- [Claude Codeの権限ルール](claude-code-permissions.md) —
  settings.json の permissions を読み書きするとき。
  権限プロンプトが出る・出ない理由を説明するとき
- [Claude Codeの新機能カタログ](claude-code-features.md) —
  Claude Code の設定・機能を提案するとき、「こういう機能はある？」と聞かれたとき。
  `claude --version` が本文記載の確認バージョンより新しいと気づいたとき（追記して更新する）
