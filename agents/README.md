# agents/ — エージェント共通のルール・ナレッジ・スキル

Claude Code と Codex の両方から使う共有資産を置く。エージェント固有の設定は
`claude-code/`（`CLAUDE.md`・`settings.json`・`statusline.sh`）側に分けている。

## 3つの機構

用途で置き場を分ける。判断基準は「毎セッション必ず効かせたいか」。

| 機構 | 何を置くか | Claude Code | Codex |
| --- | --- | --- | --- |
| `rules/` | 短い恒久的な行動ルール | 毎セッション全文ロード | `AGENTS.md` の指示で Read |
| `knowledge/` | 参照用の長いナレッジ | **索引だけ**ロード、本文は Read | 同左 |
| `skills/` | 手順・ワークフロー | name+description のみ、本文は起動時 | 同左 |

`rules/` は全文が毎回コンテキストに乗る。長い解説や、たまにしか要らない知識は
`knowledge/` へ置くこと。手順が複数ステップに及ぶものは `skills/` へ。

## 3つの公開範囲

| 層 | 実体 | git | 端末間同期 |
| --- | --- | --- | --- |
| shared | このリポジトリ（public） | 追跡 | される |
| private | `agent-knowledge-private`（private） | 追跡 | される |
| local | `~/.agents/knowledge-local/` | 対象外 | されない |

**このリポジトリは public。** 組織名・ホスト名・顧客名・認証情報を含むものは
`shared` に置かないこと。判断に迷うものは `private` へ。

## 配置

`init-mac.zsh` が張る symlink:

```
~/.agents/AGENTS.md        -> agents/AGENTS.md          （~/.codex/AGENTS.md からも）
~/.agents/skills           -> agents/skills             （~/.claude/skills からも）
~/.agents/rules/shared     -> agents/rules              （~/.claude/rules/shared からも）
~/.agents/knowledge/shared -> agents/knowledge
~/.agents/rules/private     -> agent-knowledge-private/rules     （~/.claude/rules/private からも）
~/.agents/knowledge/private -> agent-knowledge-private/knowledge
```

`~/.claude/` 側は `~/.agents/` を経由せずリポジトリを直接指す。symlink を二段にすると
解決されるかが公式ドキュメントで保証されていないため。

参照時のパスは `~/.agents/` に統一する。`~/.claude/rules/` は Claude Code に
自動ロードさせるための入口でしかなく、索引や `AGENTS.md` が指すのは常に `~/.agents/` 側。

## 追加・更新

`knowledge` スキル（`skills/knowledge/SKILL.md`）の手順に従う。
shared は dotfiles、private は `agent-knowledge-private` でそれぞれ commit & push が要る。
どちらも push しないと他の端末に反映されない。

仕様の詳細は `knowledge/agent-instruction-loading.md` を参照。
