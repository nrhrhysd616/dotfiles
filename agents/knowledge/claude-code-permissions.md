---
name: claude-code-permissions
description: Claude Codeの権限ルール（settings.jsonのpermissions）の評価順・マージ規則・書き込みツールの包含関係
---

`settings.json` の `permissions` がどう評価されるか。2026-07-24 に公式ドキュメントで
確認した内容（誤った断定でユーザーの正しい判断を一度否定したため、裏取りして記録したもの）。

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
