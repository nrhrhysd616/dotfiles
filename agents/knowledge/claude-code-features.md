---
name: claude-code-features
description: Claude Codeのバージョンアップで追加された、個人の日常利用で便利な機能・設定キーのカタログ（確認バージョン付き）
---

| 確認日 | 確認バージョン | 情報源 |
| --- | --- | --- |
| 2026-10-05 | **2.1.289** | github.com/anthropics/claude-code の CHANGELOG.md（主に 2.1.230 以降）、code.claude.com/docs |

**見直し手順:** `claude --version` が上の確認バージョンより新しければ、CHANGELOG.md を
確認バージョンより後の節だけ読み、該当するものを追記して確認日・確認バージョンを更新する。
`curl -sL https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` で取得でき、
節は `## 2.1.xxx` 見出しで区切られている。

ゲートウェイ・企業向け管理・Windows・クラウドプロバイダ固有の項目は除外している。
指示ファイルまわりの仕様の詳細は `agent-instruction-loading.md` にある。

## 指示ファイル・メモリ・スキル

| 機能 | 導入 | 何ができるか |
| --- | --- | --- |
| AGENTS.md 対応 | 2.1.277 | CLAUDE.md が無いプロジェクトで AGENTS.md を読む。`/config` の Project instructions で変更 |
| `/doctor prompt-audit` | 2.1.283 | CLAUDE.md・AGENTS.md・rules・skills・agents を古いモデル向けの書き方や矛盾の観点で監査 |
| `/skill-doctor` | 2.1.261 | 使われていないスキルと、それが消費しているコンテキストを表示 |
| `omitClaudeMd`（agent frontmatter） | 2.1.271 | カスタムサブエージェントを user / project / local の CLAUDE.md 抜きで動かす |
| claude.ai スキル同期 | 2.1.275 | アカウントで有効なスキルを `~/.claude/skills/synced/` に同期。止めるなら `syncClaudeAiSkills: false` |
| `claude plugin configure <plugin>` | 2.1.285 | プラグインのオプションと未設定項目を表示・保存 |
| Claude Mods | 2.1.287 | プラグインがペイン・ステータス行など深い挙動を変えられる（`plugin-authoring` スキル） |

## 権限・auto mode

| 機能 | 導入 | 何ができるか |
| --- | --- | --- |
| `/permissions` の Auto mode タブ | 2.1.246 | auto mode の classifier ルールを閲覧・編集 |
| ワイルドカード位置の警告 | 2.1.246 | `Bash(git * main)` のようにサブコマンドの前に `*` がある allow ルールを起動時に警告（オプションが挟まっても一致するため） |
| `permissions.blockReadsOutsideWorkingDirectories` | 2.1.257 | auto mode で作業ディレクトリ外の読み取りをブロック |
| 「Yes, but ask again next time」 | 2.1.284 | 作業ディレクトリ外の読み取りをその1回だけ許可 |
| 対話セッションの既定が auto mode | 2.1.284 | `permissions.defaultMode` 未設定なら auto で始まる。2.1.285 から別モード設定済みの人にも「auto を既定にするか」を1度だけ確認する |
| `/insights` の auto mode 推奨 | 2.1.281 | 最近のセッションで auto mode が処理できた権限プロンプト数を見積もる |

## hooks

| 機能 | 導入 | 何ができるか |
| --- | --- | --- |
| `PreModelSwitch` / `PostModelSwitch` | 2.1.251 | モデル切り替えをブロック・確認・注記できる |
| SessionStart（resume）に staleness | 2.1.251 | 再開時に、セッションがどれだけ古いかと再キャッシュの推定コストを受け取れる |

## コスト・プロンプトキャッシュ

| 機能 | 導入 | 何ができるか |
| --- | --- | --- |
| `/cost` のキャッシュ行 | 2.1.251 | セッションのキャッシュヒット率・ミス・再キャッシュ量を表示。status line スクリプトにも `prompt_cache` が渡る |
| キャッシュミスの原因表示 | 2.1.260 | ツール定義・システムプロンプトの変更や TTL 切れなど、ミスの推定原因を `/cost` と `prompt_cache` に出す |
| `/usage` の Loops 内訳 | 2.1.243 | `/loop` ごとの実行回数・トークン量を表示 |

## settings.json のキー

| キー | 導入 | 内容 |
| --- | --- | --- |
| `"attribution": false` | 2.1.281 | コミット・PR の帰属表示をすべて消す。**古い版はこのキーを含むファイルごとスキップする**ので、端末間で共有するならオブジェクト形式で書く |
| `maxProseWidth` | 2.1.282 | 広い端末で本文の幅を制限（表・コードは全幅のまま） |
| `timeFormat` / `timeZone` | 2.1.257 | ターン終了時刻やトランスクリプトの時刻表示を 12h / 24h / strftime で指定 |
| `keybindingFlavor: "readline"` | 2.1.238 | プロンプト入力の Ctrl+W を Bash と同じ挙動にする |
| `spellcheck` | 2.1.235 | aspell / hunspell / ispell でプロンプトのスペルミスに下線 |
| `bashOutputMaxChars` / `taskOutputMaxChars` | 2.1.261 | ファイルに逃がさずインラインで受け取る出力量を最大 128K 文字まで上げる |

## 操作・UI

| 機能 | 導入 | 何ができるか |
| --- | --- | --- |
| Concise 出力スタイル | 2.1.237 | 前置きや経過説明を省き結果から書く。`/config` の Output style で選ぶ |
| `/output-style [name]` | 2.1.269 | 出力スタイルの一覧・切り替え |
| `/diff` パネル | 2.1.260 | フルスクリーンモードで、未コミットの変更を会話の横に表示 |
| 送信の割り込み（Ctrl+Enter） | 2.1.275 | 実行中のターンを中断し、キュー中のメッセージをまとめて送る |
| Ctrl+C したプロンプトの復元 | 2.1.288 | 空のプロンプトで ↑ を押すと、貼り付けた画像も含めて下書きが戻る |
| `/mcp reconnect all` | 2.1.284 | 接続失敗・要認証の MCP サーバーをまとめて再接続 |
| `claude --desktop` | 2.1.285 | 現在のディレクトリ（`--continue` / `--resume` でそのセッション）をデスクトップアプリで開く |
| `/code-review --max-findings <n>\|all` | 2.1.288 | 報告件数の上限を変える。`default` を渡すまで設定が残る |

**Why:** Claude Code は数日おきにリリースされ、記憶ベースの「その機能は無い」「この設定キーは無い」が
すぐに古くなる。確認バージョンを残しておけば、どこから読み直せばよいかが分かる。

**How to apply:** Claude Code の設定や機能を提案する前、「こういう機能はある？」と聞かれたときに読む。
ここに無いから存在しないと断定せず、確認バージョンより新しい版を使っていれば CHANGELOG を差分だけ確認する。
