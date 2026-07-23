# Code Understanding Suite Implementation Plan

created: 2026-07-23 00:00 (JST)
author: AI Agent (Codex)
status: completed

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 初学者がスクリプト、SQL、統計コードを理解しやすいよう、3Skillを単一のMarkdown出力契約で連携させる。

**Architecture:** `code-understanding-pro` を親ルーター兼成果物管理者、`code-understanding-pyramid` を汎用理解フレーム、`stats-sql-comprehension` をSQL・統計専門アダプターとする。Quick Mode以外は `report.md`、`run_meta.json`、`source_manifest.json` をrun単位で保存する。

**Tech Stack:** Agent Skills Markdown、Python 3標準ライブラリ、Mermaid、JSON。

## Global Constraints

- Quick Modeはチャットのみとする。
- Quick Mode以外はMarkdownを既定出力とし、チャットには要約と保存先だけを返す。
- 出力先は `skill_out/code_understanding/<target>/run_<id>/` とする。
- 既存runを上書きしない。
- ソースコード本文や機密情報をメタデータへ複製しない。
- SQLはユーザーの明示承認なしに実行しない。
- `.agent/shared/` の未コミット削除には触れない。

---

### Task 1: 共通成果物契約

**Files:**

- Create: `.agent/skills/code-understanding-pro/references/interface.md`
- Modify: `.agent/skills/code-understanding-pro/scripts/write_report.py`
- Modify: `.agent/skills/code-understanding-pro/tests/test_report_writer.py`

**Produces:** `report.md`、`run_meta.json`、`source_manifest.json`。

- [x] モードに依存せず深い解析を `report.md` へ保存する失敗テストを追加する。
- [x] `--adapter`、`--audience`、`--source` の失敗テストを追加する。
- [x] `source_manifest.json` のSHA-256・サイズ・存在状態を検証する。
- [x] `write_report.py` を最小実装し、既存run上書き拒否を維持する。

### Task 2: 初学者向けレポート契約

**Files:**

- Create: `.agent/skills/code-understanding-pro/assets/output-template-beginner.md`
- Create: `.agent/skills/code-understanding-pro/scripts/validate_report.py`
- Create: `.agent/skills/code-understanding-pro/tests/test_report_validator.py`

**Produces:** 初学者向け必須節と品質ゲート。

- [x] 必須節欠落、未閉鎖Mermaid、根拠欠落で失敗するテストを追加する。
- [x] 正常な汎用・SQL・統計レポートが通るテストを追加する。
- [x] `validate_report.py` を実装する。

### Task 3: 3Skillの役割分離

**Files:**

- Modify: `.agent/skills/code-understanding-pro/SKILL.md`
- Modify: `.agent/skills/code-understanding-pyramid/SKILL.md`
- Modify: `.agent/skills/stats-sql-comprehension/SKILL.md`

**Produces:** 親ルーター、汎用フレーム、専門アダプターの明確な境界。

- [x] Proにルーティング表とMarkdown既定契約を追加する。
- [x] Pyramidを内部フレームとして位置付け、独自のチャット長文出力を禁止する。
- [x] Stats/SQLを専門アダプターとして位置付け、SQL非実行・粒度・JOIN検証を必須化する。

### Task 4: 専門テンプレート統一

**Files:**

- Modify: `.agent/skills/stats-sql-comprehension/assets/output-template-sql.md`
- Modify: `.agent/skills/stats-sql-comprehension/assets/output-template-stats.md`
- Modify: `.agent/skills/code-understanding-pro/assets/output-template-full.md`
- Modify: `.agent/skills/code-understanding-pro/assets/output-template-review.md`

**Produces:** 共通節を保ちながら専門項目を追加したテンプレート。

- [x] SQLテンプレートへ粒度、CTE、JOIN行数変化、検証SQLを追加する。
- [x] 統計テンプレートへ母集団、欠測、推定量、前提、バイアスを追加する。
- [x] 全テンプレートへ結論、対象と前提、用語解説、根拠行を追加する。

### Task 5: 配布・回帰検証

**Files:**

- Modify: `.agent/skills/code-understanding-pro/README.md`
- Modify: `.agent/skills/code-understanding-pro/manifest.json`
- Modify: `.agent/skills/code-understanding-pro/VERSION`
- Modify: `.agent/skills/stats-sql-comprehension/manifest.json`
- Modify: `tests/test_skill_frontmatter.py`

**Produces:** バージョン・manifest・ドキュメントが一致した配布可能なSkill群。

- [x] manifestに新規ファイルを追加する。
- [x] `code-understanding-pro` を `2.0.0-ja` に更新する。
- [x] 全Skillフロントマターと新規Pythonテストを実行する。
- [x] `git diff --check` と実レポートのスモークテストを実行する。
