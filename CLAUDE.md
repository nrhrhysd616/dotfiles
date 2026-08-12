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
6. **設定ファイルの配置**: Git・Cursor・VSCode・VSCode Insiders・Claude Code・`csctl`コマンドをシンボリックリンク、AWS CLI設定（`~/.aws/config`）をコピー（既存ファイルがある場合は上書きしない）
7. **Cline拡張設定のコピー**（VSCode Cline拡張が存在する場合のみ）
8. **SSH設定**: `sshd_config` を `/etc/ssh/` へシンボリックリンク（要sudo）、`authorized_keys` をコピー
9. **iTerm2シェルインテグレーションのインストール**
10. **macOSシステム設定**: キーリピート速度、DNS（Google Public DNS）、Finder設定など

## ディレクトリ構成

| ディレクトリ | 説明 |
| --- | --- |
| `.claude/` | このリポジトリ用のClaude Code設定（`settings.json`のみ追跡。planファイルは`.claude/plans/`に生成されるがgit管理外） |
| `aws/` | AWS CLI設定のテンプレート（`config`）。アカウント固有のARNを含むためsymlinkではなくコピーで配置される |
| `bin/` | 自作コマンド。`$HOME/.local/bin/`へシンボリックリンクされてPATHが通る（`csctl`: code-serverをTailscale経由で公開する） |
| `claude-code/` | ユーザーレベルのClaude Code設定 |
| `code-server/` | code-server（ブラウザ版VS Code）のユーザー設定。`csctl`が各インスタンスの`User/settings.json`からここへシンボリックリンクを張る。拡張機能に依存しない設定のみで構成する |
| `cursor/` | Cursorエディタの設定（`keybindings.json`のみ。`settings.json`は`vscode/settings.json`を共有） |
| `git/` | Git設定（`.gitconfig`、`.gitconfig.user.local`、`.gitignore_global`） |
| `iterm2/` | iTerm2の設定・プロファイル・カラースキーム（Monokaiテーマ各種） |
| `java/` | Javaコードフォーマッター設定（Google Styleベースのフォーマットプロファイル） |
| `ssh/` | SSHクライアント設定（`authorized_keys`） |
| `sshd/` | SSHサーバー設定（`sshd_config`。symlinkではなくコピーで配置される） |
| `vscode/` | VSCodeの設定（`settings.json`※VSCode Insiders・Cursorと共有、`keybindings.json`、Cline拡張設定） |
| `vscode-insiders/` | VSCode Insidersの設定（`keybindings.json`のみ。`settings.json`は`vscode/settings.json`を共有） |
| `zsh/` | Zshシェル設定（`.zshrc`） |
