# nrhrhysd616/dotfiles

## macOS環境構築

### シェル環境構築

1. [VSCode](https://code.visualstudio.com/download)・[VSCode Insiders](https://code.visualstudio.com/insiders/)・[Cursor](https://www.cursor.com/ja)をインストール・起動しておく

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

    * signingkey: ssh公開鍵の情報
    * name: アルファベットフルネーム
    * email: sshキーの設定と同一のGithubで利用しているメールアドレス

5. VSCodeのClineのCustom Instructionsを手動で設定する

    現状設定のエクスポートなどができず、`settings.json`ファイルでの外出しも不可能なため手動

### システム設定

* iCloud

  各種必要に応じて設定

* アクセシビリティ > ディスプレイ

  ポインタの枠線のカラー > 白
  ポインタの塗りつぶしカラー > オレンジ
  
* キーボード > キーボードショートカット…

  スクリーンショット**以外のショートカットをすべて削除**  
  「F1、F2などのキーを標準のファンクションキーとして利用」はオン
