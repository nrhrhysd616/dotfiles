# User-Level CLAUDE.md

## ナレッジの置き場

| 種類 | 実体 | 参照の仕方 |
| --- | --- | --- |
| 恒久的な行動ルール | `~/.agents/rules/` | `~/.claude/rules/` 経由で自動ロード済み |
| 参照用ナレッジ | `~/.agents/knowledge/` | 下の索引に該当したら本文を Read |
| 手順・ワークフロー | `~/.agents/skills/` | 該当時に skill を起動 |

Codex とファイルを共有している。追加・更新は `knowledge` スキルの手順に従うこと。
体系の説明は `~/.agents/README.md` にある。

## MUST: ナレッジ索引

各行の「読むタイミング」に該当したら、作業前に本文を Read すること。

@~/.agents/knowledge/shared/INDEX.md
@~/.agents/knowledge/private/INDEX.md
@~/.agents/knowledge-local/INDEX.md
