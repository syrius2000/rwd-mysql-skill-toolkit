# code-understanding-pro Markdown出力改善計画

created: 2026-07-23 00:00 (JST)
author: AI Agent (Codex)
status: completed

## 目的

`code-understanding-pro` の深い解析結果をチャットだけでなくMarkdown成果物として保存し、Mermaid図、表、見出し、段落構造を再利用できるようにする。

## 対象範囲

- Quick Modeは従来どおりチャット回答とする。
- Full / Review / Documentation / Refactoring ModeはMarkdownファイルを必ず保存する。
- 出力は `skill_out/code_understanding/<target>/run_<id>/` に隔離する。
- `run_meta.json` にモード、対象、生成時刻、Skillバージョンを記録する。
- 同じrunディレクトリが存在する場合は上書きせず失敗する。
- Markdown本文に含まれる一般的な秘密情報は保存前に伏せ字にする。
- 既存のユーザー変更、他Skill、`.agent/shared/` は変更しない。

## 実施結果

- [x] `scripts/write_report.py` を追加し、Markdown本文とメタデータをrun単位で保存する。
- [x] `scripts/collect_code_context.py` に `--output`、`--output-root`、`--run-id` を追加する。
- [x] `SKILL.md` とREADMEに、モード別のチャット応答とMarkdown保存契約を記載する。
- [x] 4種類の出力テンプレートと例題を、保存ファイル名・保存手順に合わせる。
- [x] 保存、重複拒否、秘密情報伏せ字、Quick Mode制約、コンテキスト保存を検証する。

## 実装方針

1. `scripts/write_report.py` を追加し、Markdown本文とメタデータをrun単位で保存する。
2. `scripts/collect_code_context.py` に `--output`、`--output-root`、`--run-id` を追加する。
3. `SKILL.md` とREADMEに、モード別のチャット応答とMarkdown保存契約を記載する。
4. 既存の4種類の出力テンプレートと例題を、保存ファイル名・保存手順に合わせる。
5. Pythonの単体テストで保存、重複拒否、秘密情報伏せ字、Quick Mode制約、コンテキスト保存を検証する。

## 出力契約

| モード | ファイル名 |
|---|---|
| Full | `code_understanding_report.md` |
| Review | `code_review_report.md` |
| Documentation | `code_documentation.md` |
| Refactoring | `refactoring_proposal.md` |

## 完了条件

- 深い4モードの成果物と `run_meta.json` がrunディレクトリに生成される。
- 同じrun-idの再実行で既存成果物が上書きされない。
- Markdown内のMermaidコードブロックと表がそのまま保存される。
- APIキー、Bearerトークン、パスワード等が伏せ字になる。
- Quick ModeはMarkdown保存CLIの対象外として明示される。
- 新規テストが通り、既存テストを悪化させない。
