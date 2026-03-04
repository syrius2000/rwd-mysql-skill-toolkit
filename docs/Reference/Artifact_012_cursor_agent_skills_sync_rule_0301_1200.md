created: 2026-03-01 12:00 (JST)
author: AI Agent (LLM Model)

# .cursor/skills 正本化と .agent/skills 同期ルール

## 正本

- **正本**: `.cursor/skills`
- 変更は常に .cursor/skills で行い、.agent/skills は同期ルールに従って更新する。
- シンボリックリンクは使用しない。

## 同期ルール

| 対象 | 同期方法 |
|------|----------|
| スクリプト・プロンプト | 内容を同一に保つ。.cursor を編集したら .agent へコピーで上書きする。 |
| SKILL.md（flat-file-mysql-* の3本、mysql-table-cardinality） | .cursor を正本に編集。.agent 用は「.cursor/skills」→「.agent/skills」の置換と、description への「Antigravity 用」・必要に応じ compatibility 行の追加のみ行った派生を .agent に保存する。 |

## 同期対象ファイル一覧

### スクリプト・プロンプト（内容完全一致）

コピー元 → コピー先:

- `.cursor/skills/flat-file-mysql-ddl-generation/scripts/step1_cli.py` → `.agent/skills/flat-file-mysql-ddl-generation/scripts/step1_cli.py`
- `.cursor/skills/flat-file-mysql-load-validation/scripts/step3_cli.py` → `.agent/skills/flat-file-mysql-load-validation/scripts/step3_cli.py`
- `.cursor/skills/flat-file-mysql-load-validation/prompts/step2-complete-sql.prompt.md` → `.agent/skills/flat-file-mysql-load-validation/prompts/step2-complete-sql.prompt.md`
- `.cursor/skills/mysql-table-cardinality/scripts/get_cardinality_cli.py` → `.agent/skills/mysql-table-cardinality/scripts/get_cardinality_cli.py`

### SKILL.md（.agent はパス・説明のみ差し替え）

- flat-file-mysql-ddl-generation
- flat-file-mysql-load-validation
- flat-file-mysql-overview
- mysql-table-cardinality

.cursor を編集後、次の置換で .agent 用を生成して上書きする:

1. 全文で `.cursor/skills` → `.agent/skills` に置換
2. frontmatter の description に「Antigravity 用」を追記（例: 末尾に「。Antigravity 用。」）
3. flat-file-mysql-ddl-generation のみ、必要なら `compatibility: Python 3 標準ライブラリのみ。仮想環境不要。` を frontmatter に追加

## 手動同期のコマンド例（プロジェクトルートで実行）

```bash
# スクリプト・プロンプトを .cursor から .agent へコピー
cp .cursor/skills/flat-file-mysql-ddl-generation/scripts/step1_cli.py .agent/skills/flat-file-mysql-ddl-generation/scripts/
cp .cursor/skills/flat-file-mysql-load-validation/scripts/step3_cli.py .agent/skills/flat-file-mysql-load-validation/scripts/
cp .cursor/skills/flat-file-mysql-load-validation/prompts/step2-complete-sql.prompt.md .agent/skills/flat-file-mysql-load-validation/prompts/
cp .cursor/skills/mysql-table-cardinality/scripts/get_cardinality_cli.py .agent/skills/mysql-table-cardinality/scripts/
```

SKILL.md は上記の置換ルールに従い手動または sed で編集する（自動スクリプトは必須ではない）。

## 適用範囲

- 上記ルールは **flat-file-mysql-*** の 3 スキルおよび **mysql-table-cardinality** に適用する。
- openspec-* スキルは現状どおり、本ルールの対象外。
