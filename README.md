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

    - name: アルファベットフルネーム
    - email: Githubで利用しているメールアドレス

    `user.signingkey`と`gpg.ssh.program`は端末ごとに絶対パスが変わるため、
    次の手順の`gen-mac-git-signkey`が書き込む（手で設定しない）

5. コミット署名用の鍵をSecure Enclaveに用意する

    `init-mac.zsh`が既に一度実行しているが、手順4でメールアドレスを設定した後に
    もう一度実行して、GitHubへの鍵登録と署名者リストへの追記まで済ませる

    ```zsh
    gen-mac-git-signkey
    ```

    `gh`のトークンに鍵登録用のスコープが無い場合は案内が出るので、追加してから再実行する

    ```zsh
    gh auth refresh -h github.com -s admin:ssh_signing_key,admin:public_key
    gen-mac-git-signkey
    ```

    この端末の公開鍵が`git/allowed_signers`へ追記されるので、commitしてpushする  
    そうすると他の端末でもこの端末が作った署名を検証できるようになる

    仕組みと運用は後述の[コミット署名とSSH認証（Secure Enclave）](#コミット署名とssh認証secure-enclave)を参照

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

9. AWS CLIの認証設定

    `aws/config`からコピーされた`~/.aws/config`を編集し、`login_session`にIAMユーザーのARNを設定する

    ```ini
    [default]
      login_session = arn:aws:iam::<account-id>:user/<iam-user-name>
      region = ap-northeast-1
    ```

    認証は`aws login`で行う（AWS CLI 2.32.0以降が必要）  
    ブラウザでコンソールにサインインすると一時クレデンシャルが`~/.aws/login/cache`に発行される  
    有効期限は最長12時間で、その間15分ごとに自動更新される

    ```zsh
    aws login
    aws sts get-caller-identity  # ARNを確認
    ```

    この方式では**長期のアクセスキーを一切作らない**ため、`~/.aws/credentials`は存在しない

    サインインには**MFAを設定したIAMユーザー**を使うこと  
    ルートユーザーはアカウント解約・支払い情報の変更などルート専用の操作にのみ使い、
    日常の操作やCLIからは使わない

### コミット署名とSSH認証（Secure Enclave）

コミット署名とGitHubへのSSH認証には、macOSのSecure Enclave内に作った鍵を使います。
秘密鍵はハードウェアから取り出せず、`sc_auth create-ctk-identity -t none`で作るため
署名のたびに生体認証を求められません。コミット1回あたり0.1秒程度で、
Claude等のコーディングエージェントに無人で作業させても承認待ちで止まりません。

| 要素 | 役割 |
| --- | --- |
| `bin/gen-mac-git-signkey` | 鍵の生成、GitHubへの登録、gitconfigへの反映、状態確認 |
| `bin/mac-ssh-keygen` | gitが署名時に呼ぶssh-keygenラッパー（Secure Enclaveのプロバイダを渡す） |
| `git/allowed_signers` | 全端末の公開鍵を集めた署名者リスト（`git log --show-signature`用） |
| `ssh/config` | GitHubへの認証にSecure Enclaveの鍵を使う設定 |
| `~/.ssh/id_git_sign` | ハードウェア内の鍵を指すハンドル（秘密鍵そのものではない） |

- **鍵は端末ごとに別になる**

  Secure Enclaveの秘密鍵はエクスポートできないため、`~/.ssh/id_git_sign`を他の端末へ
  コピーしても機能しません。端末ごとに鍵を作り、GitHubには端末ごとに署名キーと
  認証キーを登録します。鍵のパスとgitconfigの構造は全端末で同じなので、
  運用上の違いは出ません

- **状態を確認する**

  ```zsh
  gen-mac-git-signkey --status
  ```

  鍵、証明書の残り有効期間、gitconfigの設定値、GitHubへの登録状況、署名テストの結果が出ます

- **鍵を作り直す**

  ```zsh
  gen-mac-git-signkey --recreate
  ```

  `sc_auth`が発行する自己署名証明書の有効期間は**1年**しかないため、期限が近づいたら
  作り直します（`--status`が残り90日を切ると警告します）

  作り直したあとも、GitHub上の古い鍵と`git/allowed_signers`の古い行は消さないこと  
  消すとその鍵で署名した過去のコミットが`Unverified`になります

- **1Passwordの署名に戻す**

  旧鍵と`op-ssh-sign`は残してあるので、`~/.gitconfig.user.local`と`~/.ssh/config`を戻せば復帰できます

  ```zsh
  git config --file ~/.gitconfig.user.local gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
  git config --file ~/.gitconfig.user.local user.signingkey "<1Passwordに入れている公開鍵の文字列>"
  # ~/.ssh/config は init-mac.zsh が作ったバックアップ（config.bak.<timestamp>）から復元する
  ```

- **VSCodeなどGUIから操作したときに出るプロンプトについて**

  FIDO鍵は署名・認証の直前に`Confirm user presence for key ...`という**通知**を出します。
  標準エラーが端末ならそこへ1行出るだけですが、端末でない場合OpenSSHは`SSH_ASKPASS`の
  プログラムを起動してこれを表示しようとします。VSCodeやcode-serverは`SSH_ASKPASS`を
  自前の入力ボックスに設定しているため、答える必要のない通知が毎回プロンプトとして現れます
  （VSCodeがメッセージをパスワード要求として解釈するので`"key" has fingerprint ""`のような
  崩れた表示になります）

  `-t none`で作った鍵はSecure Enclaveが即座に応答するので確認する相手はいません。
  `git/.gitconfig`の`core.sshCommand`（fetch/push用）と`bin/mac-ssh-keygen`（署名用）の
  両方で`SSH_ASKPASS_REQUIRE=never`を設定して抑止しています。
  手動の`ssh`コマンドには影響しないため、新しいホストの鍵確認は従来どおりできます

- **セキュリティ上の前提**

  秘密鍵は取り出せませんが、`-t none`で作った鍵は**その端末で動くプロセスなら誰でも署名に使えます**。
  端末そのものが乗っ取られた場合は署名を偽造されうるので、そこは端末の安全性に依存します

### シークレット検査（gitleaks）

[gitleaks](https://gitleaks.io/)で、APIキーやトークンがコミットに混ざるのを機械的に止めています。

`.gitignore`やClaude Codeの`deny`設定が防げるのは「特定のファイル名・パス」だけで、
ソースコードにベタ書きされた値の中身までは見ていません。gitleaksがその穴を埋めます。
前述のとおり署名鍵は`-t none`で作ってあり、コーディングエージェントが無人でコミット・pushできます。
人間のレビューを挟まずに履歴が公開へ流れる経路がある以上、検査は仕組みとして持たせておく必要があります。

検査は2箇所で走ります。

| どこで | 何を見るか | すり抜けられるか |
| --- | --- | --- |
| ローカルのpre-commitフック | ステージ済みの差分 | `--no-verify`で飛ばせる |
| GitHub Actions（`.github/workflows/gitleaks.yml`） | push・プルリクエストの内容 | 飛ばせない |

#### このマシンの全リポジトリで効く

フックの実体は`git/hooks/pre-commit`で、`init-mac.zsh`が`~/.git-hooks`へ
ディレクトリごとシンボリックリンクを張ります。`git/.gitconfig`の`core.hooksPath`が
そこを指しているため、dotfilesに限らず**このマシンの全ローカルリポジトリ**で
コミット前の検査が走ります。

`core.hooksPath`はpathnameとして扱われるため`~/`が展開されます
（`gpg.ssh.program`は展開されず絶対パスが要る。同じgitconfigでも扱いが違う点に注意）。
実際の解決先は次のコマンドで確認できます。

```zsh
git rev-parse --git-path hooks
# /Users/<user>/.git-hooks
```

**効かないケースが2つあります。**

- 各リポジトリの`.git/hooks`は無効化されます。`core.hooksPath`は探索先を丸ごと差し替えるためです
- husky・lefthookを使うプロジェクトでは走りません。これらはリポジトリ側で`core.hooksPath`を
  設定するので、local設定がglobal設定に優先します。そこでの最後の砦はそのプロジェクトのCIになります

gitleaksが入っていない端末では、警告だけ出してコミットは通します。
dotfilesを適用していないマシンでコミットが一切できなくなるのを避けるためです。

#### 検出されたとき

コミットが中断され、検出したファイル・行・ルールIDが表示されます。
値そのものは`--redact`でマスクされるため、端末やログに秘密は残りません。

```txt
Finding:     token = REDACTED
RuleID:      github-pat
File:        example.txt
Line:        1
Fingerprint: example.txt:github-pat:1
```

本物のシークレットなら、混入した箇所を消してからコミットし直します。
誤検知だった場合の逃がし方は3つあります。

| 方法 | 書き方 | 効く範囲 |
| --- | --- | --- |
| インラインコメント | 検出された行の末尾に`gitleaks:allow` | その1行 |
| `.gitleaksignore` | 表示された`Fingerprint`の値を1行書く | その検出1件 |
| `.gitleaks.toml` | `[[rules.allowlists]]`にパスや正規表現を書く | パターン全体 |

いずれもリポジトリのルートに置き、CIとローカルの両方で効きます。

### コーディングエージェントの設定共有

Claude CodeとCodexに、同じルール・ナレッジ・スキルを全端末で共有させています。
実体は`agents/`配下の1箇所だけで、`init-mac.zsh`が両エージェントの探索先へシンボリックリンクを張ります。

#### 3つの置き場

用途によって置き場を分けます。判断基準は「毎セッション必ず効かせたいか」です。

| 置き場 | 何を置くか | 読み込まれ方 |
| --- | --- | --- |
| `agents/rules/` | 短い恒久的な行動ルール | 毎セッション全文 |
| `agents/knowledge/` | 参照用の長いナレッジ | **索引だけ**。本文は必要になったときだけ読まれる |
| `agents/skills/` | 手順・ワークフロー | 名前と説明だけ。本文は起動時 |

`rules/`は全文が毎回コンテキストに乗るので、長い解説やたまにしか要らない知識は`knowledge/`へ置きます。
索引に書く1行には「いつ読むか」を必ず含めます。書名だけでは呼び出されません。

#### 3つの公開範囲

**このリポジトリはpublicです。** 業務・個人固有のナレッジは別のprivateリポジトリに置きます。

| 層 | 実体 | 端末間同期 |
| --- | --- | --- |
| shared | このリポジトリ | される |
| private | `agent-knowledge-private`（privateリポジトリ） | される |
| local | `~/.agents/knowledge-local/` | されない |

`local`層をリポジトリの外に置いているのは、publicリポジトリで`git clean -xdf`を打ったときに
業務ナレッジを巻き添えで消さないためです。

新しい端末では`init-mac.zsh`が`agent-knowledge-private`を`ghq get`しますが、
アクセスできない場合は警告を出して`private`層を空のままにし、初期化は続行します。

#### 追加・更新

エージェントに「これを覚えて」「今後は〜して」と頼むと、`knowledge`スキルが起動して
層と置き場を判定し、索引への追記まで行います。`shared`へ書く前に組織名・ホスト名・
認証情報が混ざっていないか確認する手順が入っています。

**変更をpushしないと他の端末には反映されません。**

#### 2つのエージェントの違い

スキルは形式が同一なので実体を共有できますが、ルールの自動ロードは仕組みが異なります。

| | Claude Code | Codex |
| --- | --- | --- |
| スキル置き場 | `~/.claude/skills/` | `~/.agents/skills/` |
| グローバル指示 | `~/.claude/CLAUDE.md` + `~/.claude/rules/**/*.md` | `~/.codex/AGENTS.md` 1ファイルのみ |
| ファイル分割 | `@path`によるimport | **できない** |

Codexはimport機構を持たないため、`AGENTS.md`には「置き場の地図」だけを書き、
ルール本文はコマンドを明示してその場で読ませています。
Claude Codeがrulesを自動ロードするのに対し、Codexでは指示に留まるぶん遵守率は落ちます。

### miseの使い方

[mise](https://mise.jdx.dev/)は複数の言語のバージョン管理ツールです。Python、Node.js、pnpm、Bun、Go、Ruby、Terraformをmiseで管理しています。

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
  mise use python@3.11  # mise.tomlが生成される
  mise use ruby@3.3     # プロジェクトのRubyを固定したい場合
  ```

  グローバルは`latest`で運用しているため、バージョンを固定したいプロジェクトはこの方法で指定する

- **rbenv・nodenv由来のバージョンファイルについて**

  miseは`.ruby-version`や`.node-version`を**デフォルトでは読まない**  
  これらが置いてあるプロジェクトでもグローバルのバージョンが使われるため、
  尊重させたい場合はツールごとに有効化する

  ```zsh
  mise settings add idiomatic_version_file_enable_tools ruby
  ```

- **現在のバージョン確認**

  ```zsh
  python --version
  node --version
  bun --version
  ```

### CocoaPodsの使い方（iOSプロジェクト）

CocoaPodsは**グローバルにインストールせず**、プロジェクトの`Gemfile`でバージョンを固定します。  
プロジェクトごとに`pod`のバージョンがズレても衝突せず、`sudo gem install`も不要になるためです
（`init-mac.zsh`が用意するのはmise管理のRubyまで）。

- **Expoプロジェクト（`expo run:ios`）の場合**

  ルートに`Gemfile`を置くだけでよく、`pod`コマンドを自分で叩く必要はありません

  ```zsh
  cd /path/to/expo-project

  bundle init            # Gemfileを生成
  bundle add cocoapods   # GemfileとGemfile.lockにバージョンが記録される

  npx expo run:ios       # prebuildでios/を生成し、pod installまで自動実行される
  ```

  Expo CLIはgitルートまでの親ディレクトリから`Gemfile`を探し、`gem "cocoapods"`の記述があって
  `bundle exec pod --version`が通る場合に`bundle exec pod install`を使います  
  `Gemfile`が無い場合はPATH上の`pod`を探し、見つからなければ`sudo gem install cocoapods`を促してきます

  `Podfile`は`expo prebuild`が`ios/`の中に生成するため`pod init`は不要です  
  プロジェクトルートで`pod install`を実行すると`No 'Podfile' found`になります

- **Podfileを自分で管理するプロジェクトの場合**

  ```zsh
  cd /path/to/ios-project

  bundle init
  bundle add cocoapods

  bundle exec pod init      # Podfileを生成（.xcodeprojと同じ階層で実行）
  bundle exec pod install
  ```

  `Gemfile`・`Gemfile.lock`・`Podfile`・`Podfile.lock`をコミットする

- **既にGemfileがあるプロジェクト**

  ```zsh
  bundle install         # Gemfile.lockのバージョンでCocoaPodsが入る
  bundle exec pod install
  ```

- **gemの実体もプロジェクト配下に隔離する場合**

  上記だけでもバージョンは`Gemfile.lock`で固定されますが、gem自体はmise管理Rubyの共有gemディレクトリに入ります  
  完全に分けたい場合は次のように設定します

  ```zsh
  bundle config set --local path vendor/bundle  # .bundle/configが生成される
  bundle install
  echo "vendor/bundle" >> .gitignore
  ```

  `.bundle/config`はコミットしてよい（チーム全員が同じ配置になる）

**注意:**

- 手で`pod`を叩くときは`bundle exec`を付ける。グローバルに`pod`を入れていないため、
  素の`pod install`は`command not found`になる（バージョンを取り違えないための安全弁）
- Rubyのバージョンを固定したい場合は`mise use ruby@3.3`で`mise.toml`を生成する  
  miseは`.ruby-version`をデフォルトでは読まない（前述の[miseの使い方](#miseの使い方)を参照）
- 指定したバージョンにprecompiledバイナリが無いと、miseがソースビルドを行うため数分かかる  
  ビルドに必要な`openssl@3`と`libyaml`は`init-mac.zsh`が導入済み

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
