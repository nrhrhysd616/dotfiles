---
name: agent-instruction-loading
description: Claude CodeとCodexが指示ファイル（CLAUDE.md / AGENTS.md / rules / skills）をどこからどう読み込むかの仕様差
---

Claude Code と Codex は指示ファイルの置き場もロード方式も異なる。
2026-08-21 時点の公式ドキュメント（code.claude.com/docs、learn.chatgpt.com/docs）と
実機（Codex CLI 0.147.0）で確認した内容。
Claude Code 側は 2026-10-05 に **v2.1.289** の公式ドキュメント・CHANGELOG で再確認した。

| | Claude Code | Codex |
| --- | --- | --- |
| プロジェクト指示 | `CLAUDE.md`（無ければ `AGENTS.md`。v2.1.277〜） | `AGENTS.md` を root→cwd で連結 |
| スキル置き場 | `~/.claude/skills/<name>/SKILL.md`（`.agents/skills` は読まない） | `~/.agents/skills/<name>/SKILL.md` |
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
- import の最大4ホップ・1ファイル200行推奨は v2.1.289 でも変わらない。4 MiB を超えるファイルはスキップされる
- `/doctor prompt-audit`（v2.1.283〜）で CLAUDE.md / AGENTS.md / rules / skills を、
  古いモデル向けの書き方・存在しないファイル参照・相互矛盾の観点で監査できる（提案のみで勝手に書き換えない）

## Claude Code の AGENTS.md 読み込み（v2.1.277〜）

2026-10-05 に code.claude.com/docs/en/memory で確認。

- **既定（`claude-md-or-agents-md`）は「CLAUDE.md が無いときだけ AGENTS.md」。**
  cwd とその祖先に `CLAUDE.md` / `.claude/CLAUDE.md` / `CLAUDE.local.md` が1つも無ければ、
  cwd と祖先の `AGENTS.md`・`.claude/AGENTS.md` を起動時に読む。サブディレクトリの `AGENTS.md` は
  そこのファイルを Read したとき（そのディレクトリに CLAUDE.md 系が無ければ）遅延ロードされる
- 判定に**数えない**もの: `~/.claude/CLAUDE.md`、managed の CLAUDE.md、`.claude/rules/`。
  これらは AGENTS.md と並んでロードされる
- **`CLAUDE.local.md` は数える。** AGENTS.md 運用のリポジトリに個人用の `CLAUDE.local.md` を
  置いた瞬間、AGENTS.md が読まれなくなる。両方読ませたいなら下の設定を変える
- **読まないもの: `AGENTS.local.md`、`AGENTS.override.md`、`.agents/` 配下すべて。**
  このため `~/.agents/AGENTS.md`（Codex 向けの地図）が Claude Code に二重ロードされることはない
- 切り替えは `/config` の **Project instructions**。値は `claude-md-or-agents-md`（既定）/
  `claude-md-and-agents-md`（両方。同じディレクトリでは CLAUDE.md → AGENTS.md の順、既にロード済みの
  AGENTS.md はスキップ）/ `claude-md` / `managed-only`
- settings に書くなら `pluginConfigs."agents-md@builtin".options.instructionFiles`。
  **user / `--settings` / managed でのみ有効で、project・local の settings では無視される**
- `/plugin` で組み込みの `agents-md` プラグインを無効化すると AGENTS.md 対応ごと止まる
- CLAUDE.md との違い: `InstructionsLoaded` hook が発火しない／`--add-dir` 先の AGENTS.md は読まない／
  作業ディレクトリ外への `@import` はそのプロジェクトで外部 import を承認済みのときだけ（ダイアログなしで）ロード
- 旧来の回避策の扱い: `@AGENTS.md` を import する CLAUDE.md や CLAUDE.md→AGENTS.md の symlink は
  残しても二重ロードされない。AGENTS.md を出力する SessionStart hook は二重になるので消す。
  「AGENTS.md を読め」と文章で書いた CLAUDE.md は、Claude が自分で開かない限り読まれない
- v2.1.281 未満では Bedrock / Vertex / テレメトリ無効のセッションで非対応。
  アップグレード直後の初回セッションでは読まれないことがある

## claude.ai から同期されるスキル（v2.1.275〜）

2026-10-05 に code.claude.com/docs/en/skills と実測で確認。

- claude.ai アカウントでサインインしたターミナルセッションでは、アカウントで有効なスキル
  （pdf・docx など）が `~/.claude/skills/synced/` へダウンロードされ、約10分ごとに更新される。
  **一方向のコピー**で、ここを編集しても claude.ai には反映されず次の同期で上書きされる
- **このdotfilesでは `~/.claude/skills` が `agents/skills` への symlink なので、実体が public
  リポジトリの `agents/skills/synced/` に落ちる。** Codex からも `~/.agents/skills/synced/` として見える。
  `.gitignore` で `agents/skills/synced/` と `agents/skills/.trash/` を除外している
- フォルダ名 `synced` と `anthropic-skills` は予約済みで、自作スキルには使えない
- 同期を止めるなら user settings に `syncClaudeAiSkills: false`。既存の同期分は `~/.claude/skills/.trash/` へ移る

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
- **`~/.claude/settings.json` を symlink にしていても、書き込まれると実ファイルに置き換わることがある。**
  2026-10-05 に実測。Claude Code の「auto mode を既定にしますか」の承諾（v2.1.285〜）や
  iTerm2 の Claude Code 連携による hook 追加のあと、リンクが同内容の実ファイルになっていた
  （どちらが壊したかは特定できていない）。設定変更を承諾したら `ls -l ~/.claude/settings.json` で
  リンクが残っているか確認し、壊れていたら差分を `claude-code/settings.json` へ取り込んでから
  `ln -nfs` で張り直す（`init-mac.zsh` の `link_config` は差分を確認せず上書きするので先に取り込む）
- **iTerm2 の cc-status hook は、iTerm2 が書いた展開済みの絶対パスのまま残す。** iTerm2 は
  コマンド文字列の完全一致で登録済みかを判定しており、`$HOME` や `~` に書き換えると
  「連携が壊れている」と判定されて再インストールを勧められる（承諾するとファイルが書き直され、
  リンクがまた壊れる）。新しい端末で iTerm2 の初回設定が走ったとき、既存の hook を見て
  書き込みを省くかどうかは未検証

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
