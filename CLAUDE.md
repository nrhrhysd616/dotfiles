# CLAUDE.md

## リポジトリ概要

このリポジトリはmacOS開発環境のセットアップを管理する個人用dotfilesリポジトリ  
シェル設定、Git設定、エディタ設定（VSCode、VSCode Insiders、Cursor）を中央管理し、基本的にはシンボリックリンクで配置する

## 基本方針

### シンボリックリンク戦略

ほとんどの設定ファイルはこのリポジトリから対象の場所へシンボリックリンクされる

**重要:** エディタやシェル設定を変更する際は、リンク先ではなくこのリポジトリ内のソースファイルを編集すること

### パッケージマネージャーの優先順位

複数のパッケージマネージャーを用途別に使い分ける。新しいツールを追加する際は以下の優先順位に従う：

1. **Homebrew**（第一候補）: 基盤的なCLIツール全般、GUIアプリ、フォント
   例: Git、ghq、GitHub CLI、fzf、mise、AWS CLI、AWS SAM CLI、Stripe CLI、VHS、Poppler、ripgrep、Codex CLI、Fira Code、ngrok、code-server
2. **mise**: 言語ランタイム、および**プロジェクト単位でバージョンを切り替えたいCLIツール**（tfenv/asdf相当の用途）
   例: Python、Node.js、pnpm、Bun、Go、Terraform

**SDKMAN**がJavaバージョンを管理する（上記の優先順位とは独立した専用ツール）

補足:

- `curl`はmacOS標準のものを使う。Homebrew版はkeg-onlyで、使うには`.zshrc`へのPATH追加が必要になるため
- `init-mac.zsh`でHomebrew管理ツールの導入判定に`brew list`を使っているのは、コマンドの有無で判定すると
  Xcode Command Line Toolsの`git`のようなHomebrew管理外のものを「インストール済み」と誤判定し、
  未インストールのまま`brew upgrade`が走って失敗するため。formulaは`--formula`、caskは`--cask`で判定する
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
   - Python、Node.js（LTS）、pnpm、Bun、Go、Terraform（miseで管理）
   - Claude Code、Codex CLI、AWS CLI、AWS SAM CLI
   - フォント（Fira Code）、ngrok、Stripe CLI、VHS、Poppler（PDFユーティリティ）
   - ripgrep（VSCodeのTodo Tree拡張が利用する）
   - code-server（`csctl`コマンドが利用する）
5. **Javaのインストール**（SDKMANで管理）: Java 11 / 17 / 18 / 21（Amazon Corretto）
6. **設定ファイルの配置**: Git・Cursor・VSCode・VSCode Insiders・Claude Code・自作コマンド（`csctl`、`gen-mac-git-signkey`、`mac-ssh-keygen`）をシンボリックリンク、AWS CLI設定（`~/.aws/config`）をコピー（既存ファイルがある場合は上書きしない）
7. **Cline拡張設定のコピー**（VSCode Cline拡張が存在する場合のみ）
8. **SSH設定**: `sshd_config` を `/etc/ssh/` へコピー（要sudo）、`authorized_keys` をコピー、`ssh/config`と`git/allowed_signers`をシンボリックリンク（既存の実ファイルはバックアップしてから置き換える）
9. **Git署名鍵の生成**: `gen-mac-git-signkey`でSecure Enclave内に鍵を作り、gitconfigとGitHubへ登録（冪等。`user.email`未設定の初回は署名者リストへの追記だけスキップされる）
10. **iTerm2シェルインテグレーションのインストール**
11. **macOSシステム設定**: キーリピート速度、DNS（Google Public DNS）、Finder設定など

## ディレクトリ構成

| ディレクトリ | 説明 |
| --- | --- |
| `.claude/` | このリポジトリ用のClaude Code設定（`settings.json`のみ追跡。planファイルは`.claude/plans/`に生成されるがgit管理外） |
| `aws/` | AWS CLI設定のテンプレート（`config`）。アカウント固有のARNを含むためsymlinkではなくコピーで配置される |
| `bin/` | 自作コマンド。`$HOME/.local/bin/`へシンボリックリンクされてPATHが通る（`csctl`: code-serverをTailscale経由で公開する、`gen-mac-git-signkey`: Git署名鍵をSecure Enclaveに作る、`mac-ssh-keygen`: gitが署名時に呼ぶssh-keygenラッパー） |
| `claude-code/` | ユーザーレベルのClaude Code設定 |
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
