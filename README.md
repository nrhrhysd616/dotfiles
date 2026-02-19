# nrhrhysd616/dotfiles

## macOS環境構築

### シェル環境構築

1. 以下のアプリケーションをインストール&一度起動しておく

    - [VSCode](https://code.visualstudio.com/download)
    - [VSCode Insiders](https://code.visualstudio.com/insiders/)
    - [Cursor](https://www.cursor.com/ja)

2. 以下のZshコマンドを順番に実行

    ```zsh
    $git clone git@github.com:nrhrhysd616/dotfiles.git
    $chmod 744 dotfiles/init-mac.zsh
    $zsh dotfiles/init-mac.zsh
    ```

3. iTerm2の設定を反映

    iTerm2を起動しメニューの「Settings...」から以下を設定  
    General -> Settings -> Import All Settings And Data...を選択  
    `dotfiles/iterm2/iTerm2-all-settings.itermexport`のファイルを選択してインポート

4. `.gitconfig.user.local`ファイルを編集

    - signingkey: ssh公開鍵の情報
    - name: アルファベットフルネーム
    - email: sshキーの設定と同一のGithubで利用しているメールアドレス

5. sshdを再起動して設定を反映する

    ```zsh
    sudo launchctl stop com.openssh.sshd
    sudo launchctl start com.openssh.sshd
    ```

6. VSCodeのClineのCustom Instructionsを手動で設定する

    現状設定のエクスポートなどができず、`settings.json`ファイルでの外出しも不可能なため手動

### miseの使い方

[mise](https://mise.jdx.dev/)は複数の言語のバージョン管理ツールです。Python、Node.js、Bunなどをmiseで管理しています。

- **インストール済みツールの確認**

  ```zsh
  mise list
  ```

- **利用可能なバージョンの確認**

  ```zsh
  mise ls-remote python
  mise ls-remote node
  ```

- **グローバルバージョンの変更**

  ```zsh
  # 特定バージョンを指定
  mise use -g python@3.12
  mise use -g node@20
  
  # 最新版にアップデート
  mise use -g python@latest
  mise use -g node@lts
  ```

- **プロジェクトごとのバージョン指定**

  ```zsh
  # プロジェクトディレクトリで実行
  cd /path/to/project
  mise use python@3.11  # .tool-versionsファイルが生成される
  ```

- **現在のバージョン確認**

  ```zsh
  python --version
  node --version
  bun --version
  ```

### システム設定

- iCloud

  各種必要に応じて設定

- アクセシビリティ > ディスプレイ

  ポインタの枠線のカラー > 白
  ポインタの塗りつぶしカラー > オレンジ
  
- キーボード > キーボードショートカット…

  スクリーンショット**以外のショートカットをすべて削除**  
  「F1、F2などのキーを標準のファンクションキーとして利用」はオン
