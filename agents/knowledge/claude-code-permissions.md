---
name: claude-code-permissions
description: Claude Codeの権限ルール（settings.jsonのpermissions）の評価順・マージ規則・書き込みツールの包含関係
---

`settings.json` の `permissions` がどう評価されるか。2026-07-24 に公式ドキュメントで
確認した内容（誤った断定でユーザーの正しい判断を一度否定したため、裏取りして記録したもの）。

## Bashルールのワイルドカード記法

2026-08-25 に code.claude.com/docs/en/permissions で確認。

**公式が使うのはスペース区切りの `Bash(cmd *)`。** ドキュメントの例も、権限ダイアログが
「Yes, and don't ask again」で自動生成する形も、すべてこちら。`:*` は等価な別表記でしかなく、
しかも**末尾でしか認識されない**（`Bash(git:* push)` はコロンがリテラル扱いになりマッチしない）。
新しくルールを書くときはスペース区切りに揃えること。

**末尾のスペースの有無で単語境界が変わる。ここが最大の落とし穴。**

| 書き方 | 境界 | 例 |
| --- | --- | --- |
| `Bash(ls *)` | あり（直後がスペースか行末） | `ls -la` にマッチ、`lsof` にマッチしない |
| `Bash(ls*)` | なし | `ls -la` にも `lsof` にもマッチ |
| `Bash(ls:*)` | あり（` *` と等価） | `Bash(ls *)` と同じ |

その帰結として、**パス接頭辞のルールはスペース無しで書く**:

```json
"Bash(rm /private/tmp/claude-501/*)"
```

`Bash(rm /private/tmp/claude-501/:*)` と書くと ` *` 相当になり、スラッシュの直後に
スペースか行末を要求するため、配下のパス（`rm /private/tmp/claude-501/foo`）にマッチしない。
ただし境界が外れる分マッチ範囲は広がる（`*` は `..` も含む任意文字列にマッチする）。
ドキュメント自身も「引数を制約するBashパターンは脆い」と注意している。

その他:

- `*` はスペースを含む任意の文字列にマッチするので、1つで複数の引数をまたぐ
  （`Bash(git * main)` は `git push origin main` にもマッチ）
- シェル演算子（`&&` `||` `;` `|` `|&` `&` 改行）で区切られた場合、
  **各サブコマンドが独立にルールへマッチする必要がある**
- `Bash(command:rm *)` のように主要フィールドをパラメータ指定する書き方は
  無視され、起動時に警告が出る。`Bash(rm *)` と書く

## 書き込みツールの包含関係

- `Edit(path)` ルールは **Write / Edit / MultiEdit / NotebookEdit すべての書き込みツールを
  包含**して許可する
- `Write(path)` / `NotebookEdit(path)` / `Glob(path)` はファイル権限チェックにマッチせず、
  **起動時に警告が出る**。書くべきではない

## 評価順

```txt
Hooks → Deny → Ask → Permission mode → Allow → callback
```

**Ask は Allow より先に評価される。** ask に一致すれば、allow にも一致していて確認が出る。

## マージ規則

ルールは user / project / local を**マージ**する。上書きではない。

その帰結として、**グローバルの `ask` をプロジェクトの `allow` で打ち消すことはできない**。
プロンプトを消したければ `ask` 側を外すしかない。

## 編集の制約

`.claude/settings.json`（権限ファイル）は、auto mode の classifier がエージェントによる
自動編集をブロックする。変更が要る場合はユーザーに依頼する。

**Why:** 権限まわりは直感と食い違う（Ask が Allow より強い、マージであって上書きでない）。
憶測で答えると、ユーザーの正しい設定判断を否定してしまう。

**How to apply:** 権限の挙動を聞かれたら、この表を確認したうえで、
不確かならcode.claude.com/docs で裏を取ってから答える。
