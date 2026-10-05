# claude-code/ — Claude Code のユーザー設定

Claude Code 固有のユーザー設定を置く。Codex と共有するルール・ナレッジ・スキルは `agents/` 側にある。

| ファイル | 配置先 | 役割 |
| --- | --- | --- |
| `settings.json` | `~/.claude/settings.json`（シンボリックリンク） | ユーザースコープの設定。全プロジェクトに効く |
| `CLAUDE.md` | `~/.claude/CLAUDE.md`（シンボリックリンク） | ナレッジ索引を `@import` するエントリポイント |
| `statusline.sh` | `~/.claude/statusline.sh`（シンボリックリンク） | ステータスライン。RunCat Neo 向けに `runcat-metrics.json` も書き出す（git 管理外） |

リンクは `init-mac.zsh` が張る。以下は `settings.json` の解説（JSON にはコメントを書けないため、ここに書く）。
各キーの仕様は公式の [settings reference](https://code.claude.com/docs/en/settings-reference) を参照。

## 各キーの意図

| キー | 値 | 意図 |
| --- | --- | --- |
| `$schema` | schemastore | エディタで補完と検証を効かせる |
| `permissions` | 下の節 | 何を無確認で通し、何を止めるか |
| `hooks` | iTerm2 の `cc-status` | 下の節 |
| `statusLine` | `~/.claude/statusline.sh` | コンテキスト使用率・コストなどを表示する |
| `language` | `"japanese"` | 応答を日本語にする |
| `effortLevel` | `"xhigh"` | 既定の推論の深さ。モデルごとに `/effort` で保存した値があればそちらが優先される |
| `plansDirectory` | `"./.claude/plans"` | plan mode の計画ファイルを各プロジェクトの `.claude/plans/` に書く（既定は `~/.claude/plans`）。プロジェクトごとに計画を追えるようにするため。このリポジトリでは `.gitignore` 済み |
| `tui` | `"fullscreen"` | ちらつきのないフルスクリーン描画を使う |
| `theme` | `"dark-daltonized"` | 色覚多様性に配慮したダークテーマ |
| `preferredNotifChannel` | `"iterm2_with_bell"` | 完了・確認待ちを iTerm2 の通知とベルで知らせる |
| `inputNeededNotifEnabled` / `agentPushNotifEnabled` | `true` | Remote Control 経由でスマートフォンにプッシュ通知を送る |

`model` は固定していない。セッション側の選択に従わせるため。

## permissions

**方針:** 既定のモードは auto mode にする（分類器が操作ごとに安全か判定し、確認なしで進める）。
そのうえで、取り返しのつかない操作だけをルールで明示的に止める。

ルールの評価順は **deny → ask → allow** で、最初に一致したもので決まる。
ルールが具体的かどうかは関係なく、allow で deny や ask に例外を作ることはできない。
auto mode でも deny は必ず拒否され、ask は必ず確認が出る（分類器に任されない）。
ルールが無い操作は分類器が判定する。

| 種類 | 何を書くか | このリポジトリでの例 |
| --- | --- | --- |
| `deny` | どのモードでも絶対にさせない操作 | `.env` 系・秘密鍵の読み取り、`sudo rm`、`git push --force` |
| `ask` | 外部に出る、または履歴を書き換える操作。毎回人が確認する | `git push`、`gh pr create`、`git reset`、`git rebase`、`brew install` |
| `allow` | 分類器も確認もいらない定型の操作 | `git add/commit/diff`、テスト・lint・型検査、scratchpad 配下の `rm` |

書き方の注意（詳細はナレッジ `agents/knowledge/claude-code-permissions.md`）:

- Bash ルールは公式に合わせてスペース区切りの `Bash(cmd *)` で書く。`:*` は使わない
- `Bash(cmd *)` の「スペース + `*`」は単語の区切りを要求する。そのため scratchpad の `rm` は
  `Bash(rm -rf /private/tmp/claude-501/*)` のようにスペースを入れずに書いている
- `ask` に入れたものは `allow` で打ち消せない。他のリポジトリで許可したい操作は、ここの `ask` に入れない
  （以前 `git commit` を `ask` に入れていて、他のリポジトリの `allow` が効かなかった）
- `.env` の deny は `Read(*.env.*)` のようにまとめず、1つずつ書く。まとめると `.env.example` まで読めなくなる

## hooks（iTerm2 連携）

iTerm2 の Claude Code 連携（iTerm2 > Install Claude Code Integration）が追加した hooks。
10種類のイベントで `cc-status` を呼び、タブごとに Claude の状態（作業中・確認待ち・待機中）を表示する。

- **コマンドは iTerm2 が書いた絶対パス `/Users/<name>/.config/iterm2/cc-status` のまま残す。**
  iTerm2 はコマンド文字列が完全に一致するかで「インストール済み」と判定している。`$HOME` や `~` に
  書き換えると「連携が壊れている」と判定されて再インストールを勧められ、承諾するとこのファイルが書き直される
  （下の「シンボリックリンクが外れたら」につながる）
- `~/.config/iterm2/cc-status` は、iTerm2 が自分で作る iTerm.app 同梱バイナリへのリンクなので、リポジトリには含めない
- iTerm2 の無い端末では hook が失敗するが、作業を止めないエラー扱いなので実害はない

## シンボリックリンクが外れたら

Claude Code や iTerm2 がこのファイルに書き込むとき、**シンボリックリンクがリンク先と同じ内容の実ファイルに
置き換わることがある**（2026-10-05 に、auto mode を既定にする確認を承諾したときと、
iTerm2 が hook を追加したときに発生）。設定を書き込む操作の例:

- `/config`・`/tui`・`/theme` などの設定変更、auto mode を既定にするかの確認への回答
- 権限ダイアログの「Yes, and don't ask again」（project scope に書かれる場合もある）
- iTerm2 の Claude Code 連携のインストール・再インストール

こうした操作のあとは `ls -l ~/.claude/settings.json` で `->` が残っているか確認する。外れていたら:

```sh
# 1. 差分を確認し、残したい変更をリポジトリ側へ取り込む
diff ~/.claude/settings.json claude-code/settings.json
# 2. 取り込んだら一致を確かめる（出力が無ければ一致）
diff <(jq -S . ~/.claude/settings.json) <(jq -S . claude-code/settings.json)
# 3. リンクを張り直す
ln -nfs "$PWD/claude-code/settings.json" ~/.claude/settings.json
```

`init-mac.zsh` の再実行でもリンクは戻るが、差分を確認せずに上書きするので、必ず先に取り込むこと。

## 変更するとき

- `~/.claude/settings.json` ではなく、このファイルを編集してコミットする（リンク経由なので即座に反映される）
- 端末固有の値（ユーザー名を含むパスなど）は基本的に書かない。例外は上の iTerm2 hook
- 新しいキーを試すときは、そのキーが追加されたバージョンを確認する。古い版の Claude Code は、
  知らないキーを無視するだけでなく、**ファイルごと読み飛ばす**ことがある（例: `"attribution": false`）
