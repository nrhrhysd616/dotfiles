---
name: agent-instruction-loading
description: Claude CodeとCodexが指示ファイル（CLAUDE.md / AGENTS.md / rules / skills）をどこからどう読み込むかの仕様差
---

Claude Code と Codex は指示ファイルの置き場もロード方式も異なる。
2026-08-21 時点の公式ドキュメント（code.claude.com/docs、learn.chatgpt.com/docs）と
実機（Codex CLI 0.147.0）で確認した内容。

| | Claude Code | Codex |
| --- | --- | --- |
| スキル置き場 | `~/.claude/skills/<name>/SKILL.md` | `~/.agents/skills/<name>/SKILL.md` |
| SKILL.md 形式 | frontmatter `name` + `description` | 同一 |
| スキルのロード | name+description のみ先読み、本文は使用時 | 同一（初期一覧は約8,000文字まで） |
| スキルのsymlink | サポート | サポート（symlink先を追跡すると明記） |
| グローバル指示 | `~/.claude/CLAUDE.md` + `~/.claude/rules/**/*.md` | `~/.codex/AGENTS.md` 1ファイルのみ |
| ファイル分割 | `@path` import（最大4ホップ） | **import/include 機構が存在しない** |
| サイズ上限 | なし（200行推奨） | `project_doc_max_bytes` = 32 KiB |

## Claude Code 側の要点

- `~/.claude/rules/**/*.md` は**毎セッション全文ロード**される。`.md` は再帰的に探索され、
  ディレクトリ・ファイルとも symlink が解決される（実測でも確認済み）
- `paths:` frontmatter を付けたルールは、該当パターンのファイルを読んだときだけロードされる
- `@path` import は相対・絶対・`~/` すべて可。**インポート先は launch 時に全文展開される**ため、
  import してもコンテキストは減らない。索引だけを import し、本文は import しないこと
- user scope（`~/.claude/CLAUDE.md`）からの外部パス import は承認ダイアログが出ない。
  project の CLAUDE.md からの外部 import はダイアログが出る
- **block-level HTMLコメントはコンテキスト注入前に除去される。**
  常時ロードされる場所へメンテナ向けの注記をトークン消費なしで書ける
- CLAUDE.md は system prompt ではなく「system prompt 直後の user message」として配送される。
  強制力はないので、確実に実行させたい処理は hook にする
- ロード状況は `/context` の **Memory files** で確認する。`InstructionsLoaded` hook でも追える

## Claude Code の settings と auto memory の置き場

2026-09-08 に code.claude.com/docs（settings / memory）と実測で確認した内容。
サブディレクトリから起動するモノレポ（`repo/server/` `repo/client/` 等）で効いてくる。

- **project scope の設定は「起動ディレクトリ」の `.claude/` から読まれる。**
  `settings.json` も `settings.local.json` も、`repo/server/` から起動すれば
  `repo/server/.claude/` のものが読まれる。**祖先からは継承されない**
- ドキュメントの「サブディレクトリから起動すると `settings.local.json` は
  リポジトリルートのものを読み書きする」という記述は、**「Yes, and don't ask again」で
  保存される許可ルールの書き込み先**についてのもの。設定値の読み込み範囲を否定するものではない
  （`autoMemoryDirectory` を目印に3箇所から起動して実測。混同しやすい）
- **auto memory の既定の置き場は `~/.claude/projects/<project>/memory/` で、
  `<project>` は git リポジトリ由来**（cwd 由来ではない）。同一リポジトリの
  worktree・サブディレクトリは1つのメモリを共有する
- `autoMemoryDirectory` は**任意の settings scope**（user / project / local / policy /
  `--settings`）から読まれる。**値は絶対パスか `~/` 始まりなら任意のディレクトリでよい**ので、
  ユーザー名を含まない値にすれば公開リポジトリの `settings.json` へ追跡できる
- **`.claude/` を置いていない深い階層から起動すると設定が読まれず既定へ落ちる**
  （`repo/server/src/` から起動 → リポジトリ共有のメモリへ書かれる）。
  ディレクトリ単位の分離は「決めた起動位置から起動する」運用とセットでのみ成立する

## Codex 側の要点

- グローバル指示は `~/.codex/AGENTS.md`（`AGENTS.override.md` があればそちらが優先）。
  `CODEX_HOME` で場所を変えられる
- プロジェクト側は repo root から cwd へ降りながら**連結**される（後のファイルほど優先）
- **import 機構がないため、ルールを分割して自動ロードさせることはできない。**
  分割したものを届けるには連結生成するしかない
- スキルは `~/.agents/skills`（ユーザーレベル）、`$REPO_ROOT/.agents/skills`（リポジトリ）。
  `~/.codex/skills` ではない点に注意
- スキルの暗黙起動は `description` の一致で決まるため、description には
  「いつ起動すべきか / すべきでないか」を具体的に書く

**Why:** 両者でスキルは共有できるが、ルールの自動ロードは共有できない。
この差を知らないと「Codexにルールが効かない」原因を探すことになる。

**How to apply:** 共有資産は `~/.agents/` 配下に置き、Claude Code へは `~/.claude/` から
symlink を張って自動ロードさせる。Codex へは `~/.codex/AGENTS.md` を「地図」として渡し、
ルール本文は Read させる。詳細は `~/.agents/README.md` を参照。
