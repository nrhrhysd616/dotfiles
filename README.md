# nrhrhysd616/dotfiles

## macOS環境構築

### シェル環境構築

1. 以下のアプリケーションをインストール&一度起動しておく

    - [VSCode](https://code.visualstudio.com/download)
    - [VSCode Insiders](https://code.visualstudio.com/insiders/)
    - [Cursor](https://www.cursor.com/ja)
    - [Tailscale](https://tailscale.com/download)

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

5. コミット署名のローカル検証用に`~/.ssh/allowed_signers`ファイルを作成

    `git log --show-signature`で署名を検証できるようにするための設定  
    メールアドレスと公開鍵は`.gitconfig.user.local`に設定したものと同一にする

    ```zsh
    echo "<email> <signingkeyの公開鍵>" > ~/.ssh/allowed_signers
    chmod 644 ~/.ssh/allowed_signers
    ```

6. sshdを再起動して設定を反映する

    ```zsh
    sudo launchctl stop com.openssh.sshd
    sudo launchctl start com.openssh.sshd
    ```

7. VSCodeのClineのCustom Instructionsを手動で設定する

    現状設定のエクスポートなどができず、`settings.json`ファイルでの外出しも不可能なため手動

8. Tailscaleにサインインし、tailnetのHTTPS証明書を有効化する

    後述の`csctl`コマンドを使う場合のみ必要

    ```zsh
    tailscale up
    ```

    サインイン後、管理コンソールの[DNS設定](https://login.tailscale.com/admin/dns)で
    「HTTPS Certificates」を**Enable HTTPS**にする  
    これを有効にしないと`tailscale cert`が証明書を発行できず、`csctl`が起動に失敗する

    サインインさえ済ませておけば接続は切っておいてよい  
    `csctl`が必要なときだけ自動で接続し、使い終わったら自動で切断する

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

### csctlの使い方

`csctl`は任意のプロジェクトディレクトリを[code-server](https://coder.com/docs/code-server)（ブラウザ版VS Code）として起動し、
Tailscale経由で公開するコマンドです。iPadなど同じtailnetに参加している端末のブラウザからプロジェクトを開けます。

各インスタンスはこのマシンのTailscale IPに直接バインドし、`tailscale cert`が発行した証明書でTLSを終端するため、
`https://<MagicDNS名>:<ポート>/`でアクセスできます。インターネットには一切公開されません。

- **起動して公開する**

  ```zsh
  # ディレクトリを指定するだけ（ポートは18080から空きを自動選択、インスタンス名はディレクトリ名）
  csctl start ~/Documents/Project/github.com/nrhrhysd616/dotfiles

  # カレントディレクトリを公開する
  csctl start

  # ポートと名前を明示する（複数プロジェクトを同時に公開できる）
  csctl start ~/work/api --port 18090 --name api
  ```

  起動に成功するとURLとパスワードが表示されます。パスワードは全インスタンス共通で、初回に自動生成されます。

- **一覧・状態・ログ**

  ```zsh
  csctl list             # 全インスタンスの一覧
  csctl status api       # 1つの詳細（URL、PID、ログの場所など）
  csctl logs -f api      # ログを追尾
  csctl url api          # URLだけを出力
  csctl open api         # ローカルのブラウザで開く
  ```

- **停止**

  ```zsh
  csctl stop api         # 名前で停止
  csctl stop 18090       # ポートで停止
  csctl stop all         # 全部停止
  csctl restart api      # 同じディレクトリ・ポートで再起動
  ```

- **その他**

  ```zsh
  csctl doctor           # 依存コマンドとTailscaleの状態を確認
  csctl password         # 共通パスワードを表示
  csctl password --reset # パスワードを再生成（再起動するまで既存インスタンスは旧パスワード）
  csctl cert             # TLS証明書の発行・更新
  csctl font install     # Fira Codeをcode-server自身から配信する（後述）
  csctl help             # 全コマンドのヘルプ
  ```

- **エディタ設定とテーマ**

  設定は`code-server/settings.json`で管理し、`csctl`が各インスタンスの
  `User/settings.json`からシンボリックリンクを張るため全インスタンスで共有される。
  code-server上で設定を変更するとリポジトリ側のファイルが直接書き換わる。

  `vscode/settings.json`（デスクトップ版）とは別ファイルにしている。ブラウザ版では
  拡張機能を入れ直す必要があり、外部アプリ連携も動かないため、
  **拡張機能に依存しない設定だけ**を持たせている。

  - テーマは組み込みの`Monokai`とアイコンテーマ`vs-seti`を使う（拡張機能不要）
  - Monokai Proを使いたい場合はcode-server上で拡張機能`monokai.theme-monokai-pro-vscode`を
    インストールし、`code-server/settings.json`の`workbench.colorTheme`を書き換える
  - 拡張機能は`~/.local/share/csctl/extensions`に置かれ**全インスタンスで共有**されるため、
    インストールは一度だけでよい

- **Fira Codeを全端末で使う**

  `editor.fontFamily`はブラウザが動いている端末のフォントを参照するため、
  Fira Codeが入っていないiPadなどでは効かずフォールバックされる。
  以下を実行するとcode-server自身がWebフォントとして配信するようになり、どの端末でも適用される。

  ```zsh
  csctl font install   # 有効化（実行後、起動中のインスタンスはrestartが必要）
  csctl font status    # 状態確認
  csctl font remove    # 元に戻す
  ```

  この処理はcode-server本体のCSSに`@font-face`を追記し、`~/Library/Fonts`のFira Codeを
  配信ディレクトリへコピーする。**code-serverを更新すると失われる**が、
  一度有効にしておけば次回の`csctl start`時に自動で貼り直される。

- **動作のカスタマイズ**

  | 環境変数 | 説明 |
  | --- | --- |
  | `CSCTL_PORT_START` | ポート自動選択の開始番号（既定: 18080、そこから20個スキャンする） |
  | `CSCTL_AUTO_UP` | `0`を指定すると自動`tailscale up`を無効化する |
  | `CSCTL_AUTO_DOWN` | `0`を指定すると自動`tailscale down`を無効化する |
  | `CSCTL_CODE_SERVER_BIN` | code-serverのパスを明示する |
  | `CSCTL_TAILSCALE_BIN` | tailscaleのパスを明示する |

Tailscaleの自動接続について:

- Tailscaleを常駐させる必要はありません。`csctl start`が未接続（Stopped）を検出すると自動で`tailscale up`し、
  最後のインスタンスを停止した時点で自動的に`tailscale down`します
- 自動切断は**csctlが接続した場合のみ**行われます。自分で`tailscale up`した接続はcsctlが切ることはありません
- サインインが必要な状態（NeedsLogin）ではブラウザ操作が要るため自動接続しません。手動で`tailscale up`してください

補足:

- 証明書は起動のたびに有効期限をチェックし、残り30日を切っていれば自動で更新されます
- 拡張機能と`settings.json`は全インスタンスで共有されますが、開いているタブやウィンドウ状態などの
  ユーザーデータはインスタンスごとに分離されます（VS Codeは同じuser-data-dirを複数のサーバーで同時に使えないため）
- Macがスリープするとインスタンスも応答しなくなります。常時アクセスしたい場合は`caffeinate`などで抑止してください
- Macを再起動するとインスタンスは終了します（自動起動はしないため、再度`csctl start`が必要）

### システム設定

- iCloud

  各種必要に応じて設定

- アクセシビリティ > ディスプレイ

  ポインタの枠線のカラー > 白
  ポインタの塗りつぶしカラー > オレンジ
  
- キーボード > キーボードショートカット…

  スクリーンショット**以外のショートカットをすべて削除**  
  「F1、F2などのキーを標準のファンクションキーとして利用」はオン
