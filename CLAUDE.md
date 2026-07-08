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

1. **Nix**（第一候補）: 基盤的なCLIツール全般。宣言的でバージョン管理不要、再現性が高い
   例: Git、ghq、GitHub CLI、curl、fzf、mise、Go、AWS CLI、AWS SAM CLI、Stripe CLI、VHS
2. **mise**: 言語ランタイム、および**プロジェクト単位でバージョンを切り替えたいCLIツール**（tfenv/asdf相当の用途）
   例: Python、Node.js、pnpm、Bun、Terraform
3. **Homebrew**（最終手段）: GUIアプリ・フォントなど、Nix/miseでカバーできない、またはNixで問題が起きるもの
   例: Codex CLI、Fira Code（Nixでのフォント配置にバグがあるため）、ngrok

**SDKMAN**がJavaバージョンを管理する（上記の優先順位とは独立した専用ツール）

## 初期化スクリプト

### `init-mac.zsh`

新規macOS環境のセットアップを自動化するスクリプト。macOS以外では実行不可。
以下の処理を順番に行う：

1. **パッケージマネージャーのインストール**: Nix（パッケージ管理のメイン）・Homebrew（一部パッケージ用）
2. **Zsh設定**: `zsh/.zshrc` をホームディレクトリへシンボリックリンク
3. **Xcode Command Line Toolsのインストール**
4. **開発ツールのインストール**（未インストールの場合のみ）:
   - Git、ghq、GitHub CLI、curl、fzf（Nixで管理）
   - mise（マルチ言語バージョンマネージャー）、Go（Nixで管理）
   - SDKMAN（Java用バージョンマネージャー）
   - Python、Node.js（LTS）、pnpm、Bun、Terraform（miseで管理）
   - Claude Code、Codex CLI、AWS CLI、AWS SAM CLI
   - フォント（Fira Code）、ngrok、Stripe CLI、VHS
5. **Javaのインストール**（SDKMANで管理）: Java 11 / 17 / 18 / 21（Amazon Corretto）
6. **設定ファイルのシンボリックリンク作成**: Git・Cursor・VSCode・VSCode Insiders・Claude Code
7. **Cline拡張設定のコピー**（VSCode Cline拡張が存在する場合のみ）
8. **SSH設定**: `sshd_config` を `/etc/ssh/` へシンボリックリンク（要sudo）、`authorized_keys` をコピー
9. **iTerm2シェルインテグレーションのインストール**
10. **macOSシステム設定**: キーリピート速度、DNS（Google Public DNS）、Finder設定など

## ディレクトリ構成

| ディレクトリ | 説明 |
| --- | --- |
| `.claude/` | このリポジトリ用のClaude Code設定（`settings.json`のみ追跡。planファイルは`.claude/plans/`に生成されるがgit管理外） |
| `claude-code/` | ユーザーレベルのClaude Code設定 |
| `cursor/` | Cursorエディタの設定（`keybindings.json`のみ。`settings.json`は`vscode/settings.json`を共有） |
| `git/` | Git設定（`.gitconfig`、`.gitconfig.user.local`、`.gitignore_global`） |
| `iterm2/` | iTerm2の設定・プロファイル・カラースキーム（Monokaiテーマ各種） |
| `java/` | Javaコードフォーマッター設定（Google Styleベースのフォーマットプロファイル） |
| `ssh/` | SSHクライアント設定（`authorized_keys`） |
| `sshd/` | SSHサーバー設定（`sshd_config`。symlinkではなくコピーで配置される） |
| `vscode/` | VSCodeの設定（`settings.json`※VSCode Insiders・Cursorと共有、`keybindings.json`、Cline拡張設定） |
| `vscode-insiders/` | VSCode Insidersの設定（`keybindings.json`のみ。`settings.json`は`vscode/settings.json`を共有） |
| `zsh/` | Zshシェル設定（`.zshrc`） |
