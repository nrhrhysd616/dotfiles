# CLAUDE.md

## リポジトリ概要

このリポジトリはmacOS開発環境のセットアップを管理する個人用dotfilesリポジトリ  
シェル設定、Git設定、エディタ設定（VSCode、VSCode Insiders、Cursor）を中央管理し、基本的にはシンボリックリンクで配置する

## 基本方針

### シンボリックリンク戦略

ほとんどの設定ファイルはこのリポジトリから対象の場所へシンボリックリンクされる

**重要:** エディタやシェル設定を変更する際は、リンク先ではなくこのリポジトリ内のソースファイルを編集すること

### コーディングエージェントの設定共有

Claude CodeとCodexで、ルール・ナレッジ・スキルを`agents/`配下に集約して共有する。
両者はスキルの形式（`SKILL.md`の`name`/`description` frontmatter）が同一でsymlinkにも対応するため、
実体は1つで済む。一方でルールの自動ロードは仕組みが異なり、Claude Codeは`~/.claude/rules/`配下を
毎セッション全文ロードするが、Codexは`~/.codex/AGENTS.md`の1ファイルしか読まずimport機構も持たない。
そのためCodexへは`AGENTS.md`を「置き場の地図」として渡し、ルール本文はコマンドを明示してReadさせている。
仕様の詳細は`agents/knowledge/agent-instruction-loading.md`にある。

**このリポジトリはpublic。** 業務・個人固有のナレッジは別のprivateリポジトリ
（`agent-knowledge-private`）に置き、`init-mac.zsh`が`~/.agents/`配下へリンクする。
どちらの層に書くかの判定は`agents/skills/knowledge/SKILL.md`の手順に従う。
端末固有のものは同期対象外の`~/.agents/knowledge-local/`へ置く
（publicリポジトリで`git clean -xdf`を打ったときに巻き添えで消さないよう、あえてリポジトリ外にしている）。

### パッケージマネージャーの優先順位

複数のパッケージマネージャーを用途別に使い分ける。新しいツールを追加する際は以下の優先順位に従う：

1. **Homebrew**（第一候補）: 基盤的なCLIツール全般、GUIアプリ、フォント
   例: Git、ghq、GitHub CLI、fzf、mise、AWS CLI、AWS SAM CLI、Stripe CLI、VHS、Poppler、ripgrep、Codex CLI、Fira Code、ngrok、code-server、OpenSSL 3・libyaml（Rubyのビルド依存）
2. **mise**: 言語ランタイム、および**プロジェクト単位でバージョンを切り替えたいCLIツール**（tfenv/asdf相当の用途）
   例: Python、Node.js、pnpm、Bun、Go、Ruby、Terraform

**SDKMAN**がJavaバージョンを管理する（上記の優先順位とは独立した専用ツール）

補足:

- `curl`はmacOS標準のものを使う。Homebrew版はkeg-onlyで、使うには`.zshrc`へのPATH追加が必要になるため
- `init-mac.zsh`でHomebrew管理ツールの導入判定に`brew list`を使っているのは、コマンドの有無で判定すると
  Xcode Command Line Toolsの`git`のようなHomebrew管理外のものを「インストール済み」と誤判定し、
  未インストールのまま`brew upgrade`が走って失敗するため。formulaは`--formula`、caskは`--cask`で判定する
- miseのRubyはprecompiledバイナリがあればそれを使い、無ければruby-buildでソースビルドされる。
  precompiledはApple Silicon向けの一部バージョンのみなので、プロジェクトの`.ruby-version`が
  古いバージョンを指すとビルドが走る。その保険として`openssl@3`（macOS標準のLibreSSLでは
  openssl拡張がビルドできない）と`libyaml`（無いとpsychが入らずbundlerやCocoaPodsが動かない）を
  Homebrewで先に入れている
- Rubyの導入判定には`command -v ruby`ではなく`mise which ruby`を使う。macOS標準の
  `/usr/bin/ruby`を「インストール済み」と誤判定するため（Homebrewで`brew list`を使うのと同じ理由）
- CocoaPodsはグローバルに入れない。プロジェクトごとに`Gemfile`で固定して`bundle exec pod`で使う
  （プロジェクト間で`pod`のバージョンがズレても衝突しないため）。dotfilesが用意するのはRubyまで
- 以前はNixを第一候補にしていたが、ストアパスが更新のたびに変わるため絶対パスを要求する設定
  （Todo Tree拡張のripgrepパス）で使えないなど例外が積み上がり、管理コストが見合わないため撤廃した

### コミット署名とSSH認証

Gitのコミット署名とGitHubへのSSH認証には、macOSのSecure Enclave内に作った鍵を使う
（`sc_auth create-ctk-identity -k p-256-ne -t none`）

- `-t none`で作るため署名のたびに生体認証ダイアログが出ない。コーディングエージェントに
  無人でコミット・pushさせられる（以前は1Passwordの`op-ssh-sign`とSSH agentを使っていたが、
  コミット・pushごとに人間の承認が必要で作業が止まっていた）
- **秘密鍵はエクスポート不可なので鍵は端末ごとに別になる。** `~/.ssh/id_git_sign`は
  ハードウェア内の鍵を指すハンドルでしかなく、他の端末にコピーしても使えない。
  新しい端末では`gen-mac-git-signkey`で鍵を作り、GitHubに署名キーと認証キーを追加登録する
- 署名検証用の公開鍵は`git/allowed_signers`に全端末分を集約し、`~/.ssh/allowed_signers`へ
  シンボリックリンクする。古い鍵の行は消さない（消すとその鍵で署名した過去のコミットが
  検証できなくなる）
- `sc_auth`が発行する自己署名証明書の有効期間は1年しかないため、期限が近づいたら
  `gen-mac-git-signkey --recreate`で作り直す運用になる（`--status`が残り90日で警告する）
- `gpg.ssh.program`と`user.signingkey`は`~/.gitconfig.user.local`に**絶対パス**で書く。
  gitがこれらのチルダを展開しないため、全端末で共有する`git/.gitconfig`には書けない
- FIDO鍵は署名・認証の直前に`Confirm user presence`という通知を出す。標準エラーが端末でないと
  OpenSSHは`SSH_ASKPASS`のプログラムでこれを表示しようとし、VSCodeやcode-serverは
  `SSH_ASKPASS`を自前の入力ボックスに設定しているため、答える必要のない通知が毎回
  プロンプトとして現れる。`core.sshCommand`（fetch/push用）と`bin/mac-ssh-keygen`（署名用）の
  両方で`SSH_ASKPASS_REQUIRE=never`を設定して抑止している

### 自作コマンドの命名

`bin/`配下のコマンドが特定のプラットフォームや条件でしか動かないなら、**名前にその範囲を含める**。
`ssh-sign`のような汎用的すぎる名前は避ける（実際に`gen-mac-git-signkey`・`mac-ssh-keygen`へ改名した）。

- macOS専用なら`mac-`のようなプレフィックスで範囲を示す。
  広い意味の名前を付けると、`bin/`に並んだときにどれが環境依存なのか分からなくなる
- ラッパーは役割を言い換えず、ラップ対象の名前をそのまま使う
  （`ssh-keygen`のラッパーは`mac-ssh-keygen`）
- 名前が`gen-`のように単一の目的を表すなら、インターフェースもサブコマンドではなく
  フラグ（`--status`、`--recreate`）にして名前と整合させる

## 初期化スクリプト

### `init-mac.zsh`

新規macOS環境のセットアップを自動化するスクリプト。macOS以外では実行不可。
以下の処理を順番に行う：

1. **パッケージマネージャーのインストール**: Homebrew（パッケージ管理のメイン）
2. **Zsh設定**: `zsh/.zshrc` をホームディレクトリへシンボリックリンク
3. **Xcode Command Line Toolsのインストール**
4. **開発ツールのインストール**（未インストールの場合のみ）:
   - Git、ghq、GitHub CLI、fzf（Homebrewで管理）
   - mise（マルチ言語バージョンマネージャー、Homebrewで管理）
   - SDKMAN（Java用バージョンマネージャー）
   - OpenSSL 3、libyaml（miseのRubyがソースビルドになった場合に必要、Homebrewで管理）
   - Python、Node.js（LTS）、pnpm、Bun、Go、Ruby、Terraform（miseで管理）
   - Claude Code、Codex CLI、AWS CLI、AWS SAM CLI
   - フォント（Fira Code）、ngrok、Stripe CLI、VHS、Poppler（PDFユーティリティ）
   - ripgrep（VSCodeのTodo Tree拡張が利用する）
   - code-server（`csctl`コマンドが利用する）
5. **Javaのインストール**（SDKMANで管理）: Java 11 / 17 / 18 / 21（Amazon Corretto）
6. **設定ファイルの配置**: Git・Cursor・VSCode・VSCode Insiders・Claude Code・自作コマンド（`csctl`、`gen-mac-git-signkey`、`mac-ssh-keygen`）をシンボリックリンク、AWS CLI設定（`~/.aws/config`）をコピー（既存ファイルがある場合は上書きしない）
   - **エージェント共通設定**（`agents/`）: ルール・ナレッジ・スキルを`~/.agents/`と`~/.claude/`・`~/.codex/`へシンボリックリンク。
     非公開ナレッジのリポジトリ（`agent-knowledge-private`）を`ghq get`し、取得できた場合のみ`private`層をリンクする。
     アクセス権のない端末でも初期化が止まらないよう、`ghq get`の前に`gh repo view`でアクセス可否を確認している
     （`ghq get`は存在しないリポジトリに対して認証待ちでハングするため、これを存在確認に使ってはいけない）
7. **Cline拡張設定のコピー**（VSCode Cline拡張が存在する場合のみ）
8. **SSH設定**: `sshd_config` を `/etc/ssh/` へコピー（要sudo）、`authorized_keys` をコピー、`ssh/config`と`git/allowed_signers`をシンボリックリンク（既存の実ファイルはバックアップしてから置き換える）
9. **Git署名鍵の生成**: `gen-mac-git-signkey`でSecure Enclave内に鍵を作り、gitconfigとGitHubへ登録（冪等。`user.email`未設定の初回は署名者リストへの追記だけスキップされる）
10. **iTerm2シェルインテグレーションのインストール**
11. **macOSシステム設定**: キーリピート速度、DNS（Google Public DNS）、Finder設定など

## ディレクトリ構成

| ディレクトリ | 説明 |
| --- | --- |
| `.claude/` | このリポジトリ用のClaude Code設定（`settings.json`のみ追跡。planファイルは`.claude/plans/`に生成されるがgit管理外） |
| `agents/` | Claude CodeとCodexで共有するルール・ナレッジ・スキル（`rules/`: 毎セッション全文ロードされる行動ルール、`knowledge/`: 索引だけロードし本文は必要時に読む参照情報、`skills/`: 手順、`AGENTS.md`: Codex向けの地図）。詳細は`agents/README.md` |
| `aws/` | AWS CLI設定のテンプレート（`config`）。アカウント固有のARNを含むためsymlinkではなくコピーで配置される |
| `bin/` | 自作コマンド。`$HOME/.local/bin/`へシンボリックリンクされてPATHが通る（`csctl`: code-serverをTailscale経由で公開する、`gen-mac-git-signkey`: Git署名鍵をSecure Enclaveに作る、`mac-ssh-keygen`: gitが署名時に呼ぶssh-keygenラッパー） |
| `claude-code/` | Claude Code固有のユーザー設定（`CLAUDE.md`: ナレッジ索引を`@import`するエントリポイント、`settings.json`、`statusline.sh`）。エージェント非依存の資産は`agents/`側にある |
| `code-server/` | code-server（ブラウザ版VS Code）のユーザー設定。`csctl`が各インスタンスの`User/settings.json`からここへシンボリックリンクを張る。拡張機能に依存しない設定のみで構成する |
| `cursor/` | Cursorエディタの設定（`keybindings.json`のみ。`settings.json`は`vscode/settings.json`を共有） |
| `git/` | Git設定（`.gitconfig`、`.gitconfig.user.local`、`.gitignore_global`、`allowed_signers`※全端末の署名検証用公開鍵。`~/.ssh/`へsymlinkされる） |
| `iterm2/` | iTerm2の設定・プロファイル・カラースキーム（Monokaiテーマ各種） |
| `java/` | Javaコードフォーマッター設定（Google Styleベースのフォーマットプロファイル） |
| `ssh/` | SSHクライアント設定（`config`※GitHub認証にSecure Enclaveの鍵を使う設定、`authorized_keys`） |
| `sshd/` | SSHサーバー設定（`sshd_config`。symlinkではなくコピーで配置される） |
| `vscode/` | VSCodeの設定（`settings.json`※VSCode Insiders・Cursorと共有、`keybindings.json`、Cline拡張設定） |
| `vscode-insiders/` | VSCode Insidersの設定（`keybindings.json`のみ。`settings.json`は`vscode/settings.json`を共有） |
| `zsh/` | Zshシェル設定（`.zshrc`） |
