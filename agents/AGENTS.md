# エージェント共通ガイド

ルール・ナレッジ・スキルは `~/.agents/` 配下にある。Claude Code と Codex で共有している。

## MUST: セッション開始時に読む

`~/.agents/rules/` 配下の `.md` は必ず守る行動ルール。作業を始める前に、
次のコマンドをそのまま実行して全文を読むこと:

```sh
cat ~/.agents/rules/*/*.md
```

<!--
  Claude Code は ~/.claude/rules/ 経由で自動ロードするため、この指示は主に Codex 向け。
  コマンドを具体的に示しているのは、パスだけ伝えると Codex が独自に組み立てた
  find/rg のワンライナーで失敗することがあったため。
  このHTMLコメントはコンテキスト注入前に除去される（Claude Code の場合）。
-->

## 参照用ナレッジ

必要になったときだけ本文を読む。索引は3つ:

| 索引 | 範囲 |
| --- | --- |
| `~/.agents/knowledge/shared/INDEX.md` | 公開・全端末同期 |
| `~/.agents/knowledge/private/INDEX.md` | 非公開・全端末同期 |
| `~/.agents/knowledge-local/INDEX.md` | この端末限定 |

各索引は「トピック名 — いつ読むか」の1行で構成される。
トリガーに該当したら、作業前に本文を Read すること。

## 手順・ワークフロー

`~/.agents/skills/<name>/SKILL.md`。Claude Code / Codex とも自動で認識する。

## 追加・更新

`knowledge` スキルの手順に従うこと。層（公開範囲）と機構（rules / knowledge / skills）の
判定を誤ると、非公開情報が公開リポジトリに入る。
