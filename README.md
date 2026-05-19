# IDE用スキル管理リポジトリ

このリポジトリは、各種 IDE（Cursor / Antigravity）で使用する **Skill** を一元管理します。

## リポジトリ構造

```
.
├── .agent/skills/          # Antigravity 用スキル
├── .cursor/skills/         # Cursor 用スキル（正本）
├── docs/
│   ├── Artifacts/          # 生成ドキュメント
│   ├── Reference/          # 参照ドキュメント（同期ルール等）
│   ├── Archive/            # アーカイブ
├── skill_out/              # スキル実行の生成物
├── AnotherPJ/              # 補助プロジェクト
├── flat_file_mysql/        # フラットファイル MySQL 関連資産
└── tests/                  # テスト
```

## 使い方（最短）

- **スキル定義**: 各スキル配下の `SKILL.md`
- **実行用テンプレ**: `templates/`（R / Rmd / Python 等）
- **出力先**: 原則 `./skill_out/` 配下（スキルごとにサブディレクトリ）

例: `questionnaire-batch-analysis`（テストデータ）

```bash
Rscript tests/test_questionnaire_batch_smoke.R
open tests/skill_out_smoke/q01_gender_dept/report.html
```

## 管理スキル一覧

`.agent/skills` と `.cursor/skills` の両方に同一の11スキルを配置しています（正本は `.agent/skills`）。

| スキル名 | 概要 |
|---|---|
| `flat-file-mysql-overview` | CP932 CSV → MySQL 投入の全体像（Step 1→2→3） |
| `flat-file-mysql-ddl-generation` | CP932 CSV から DDL 用サンプル SQL と簡易レポート生成（Step 1） |
| `flat-file-mysql-load-validation` | SQL 作成支援・DB 実行・件数比較（Step 2〜3） |
| `mysql-er-diagram` | DB メタから辞書 CSV / Draw.io XML / PlantUML の ER 図生成 |
| `mysql-table-cardinality` | 総行数・カーディナリティ等を CSV/JSON 出力 |
| `mysql-entity-matrix` | 特定 ID の存在フラグ `[0,1]` マトリックス生成 |
| `questionnaire-batch-analysis` | 設問設定 CSV で複数設問を一括処理し、HTML レポートと `summary.csv` を生成 |
| `vcd-categorical-analysis` | 名義カテゴリ（3-way）の3ステップ分析（集計 → AI考察 → dashboard/report HTML） |
| `vcd-categorical-reporting` | **非推奨**（analysis に統合。参照テンプレのみ） |
| `vcd-bayesian-evidence-analysis` | 大標本時の効果量・BIC/BF 視点の評価 |
| `security-vulnerability-check` | ソースコードの脆弱性チェック（SQLi / OS コマンド / パストラバーサル等） |

## テスト

R ベースの smoke テストが中心です（`tests/test_*.R`）。例:

```bash
Rscript tests/test_questionnaire_batch_smoke.R
Rscript tests/test_vcd_categorical_smoke.R
```

## 生成物（例）

- `questionnaire-batch-analysis`: `tests/skill_out_smoke/`（テスト実行時）
- `vcd-categorical-analysis`: `skill_out/vcd_categorical/`

## 同期ルール

- **正本**: `.agent/skills` ディレクトリ
- **同期先**: `.cursor/skills`（Cursor 用ミラー）
- シンボリックリンクは使用しない

詳細な同期ルール（対象ファイル一覧、置換ルール、コマンド例）は以下を参照：

- [AGENTS.md](AGENTS.md)

### 同期対象の概要

| 種別 | 同期方法 |
|------|----------|
| 全スキル | `.agent/skills` を編集後、`rsync -a --delete .agent/skills/ .cursor/skills/` |
| flat-file-mysql-* の SKILL.md | `.agent` パス（`.agent/skills/...`）で記載 |
