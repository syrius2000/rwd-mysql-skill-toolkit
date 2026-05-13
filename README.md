# 統合DB構築・分析スキル管理リポジトリ

このリポジトリは、ローカル CSV やフラットファイルから RDBMS を構築し、MySQL/MariaDB 上で探索・Query作成・分析用データセット抽出を行い、R/R Markdown による分析へつなぐための **統合DB構築・分析スキル** を管理します。

## リポジトリ構造

```
.
├── .agent/skills/          # Antigravity, Codex など汎用スキル
├── .cursor/skills/         # Cursor 用スキル（正本）
├── docs/
│   ├── Artifacts/          # 生成ドキュメント
│   ├── Reference/          # 参照ドキュメント（同期ルール等）
│   ├── Archive/            # アーカイブ
├── skill_out/              # スキル実行の生成物
├── sql/                    # Query作成支援で作成したSQL資産
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

## ワークフロー

```mermaid
flowchart LR
  A[CSV / flat files] --> B[構築系]
  B --> C[MySQL / MariaDB]
  C --> D[探索系]
  D --> E[Query作成支援]
  E --> F[sql/]
  F --> G[分析系]
```

| 系統 | スキル | 役割 |
|---|---|---|
| 構築系 | `flat-file-mysql-overview`, `flat-file-mysql-ddl-generation`, `flat-file-mysql-load-validation` | DBを作る |
| 探索系 | `mysql-er-diagram`, `mysql-table-cardinality`, `mysql-entity-matrix`, `mysql-create-query-support` | 構造・分布・ID所在を確認し、望むQueryを作る |
| 分析系 | `questionnaire-batch-analysis`, `vcd-categorical-analysis`, `vcd-categorical-reporting`, `vcd-bayesian-evidence-analysis` | 抽出結果を分析・レポート化する |
| 保守系 | `security-vulnerability-check` | スクリプトとSQL支援の安全性を確認する |

## 管理スキル一覧

`.agent/skills` と `.cursor/skills` の両方に同一の12スキルを配置しています。

| スキル名 | 概要 |
|---|---|
| `flat-file-mysql-overview` | CP932 CSV → MySQL 投入の全体像（Step 1→2→3） |
| `flat-file-mysql-ddl-generation` | CP932 CSV から DDL 用サンプル SQL と簡易レポート生成（Step 1） |
| `flat-file-mysql-load-validation` | SQL 作成支援・DB 実行・件数比較（Step 2〜3） |
| `mysql-er-diagram` | DB メタから辞書 CSV / Draw.io XML / PlantUML の ER 図生成 |
| `mysql-table-cardinality` | 総行数・カーディナリティ等を CSV/JSON 出力 |
| `mysql-entity-matrix` | 特定 ID の存在フラグ `[0,1]` マトリックス生成 |
| `mysql-create-query-support` | 自然文の分析目的から本 SQL・検証 SQL・query note を作成する支援 |
| `questionnaire-batch-analysis` | 設問設定 CSV で複数設問を一括処理し、HTML レポートと `summary.csv` を生成 |
| `vcd-categorical-analysis` | 名義カテゴリ（最大 3-way）のクロス表・残差・vcd 可視化・対数線形モデル |
| `vcd-categorical-reporting` | `vcd-categorical-analysis` の出力を読み、判断ファーストのAI評価レポートを作成 |
| `vcd-bayesian-evidence-analysis` | 大標本でP値と実質的意義が乖離する場合に、効果量・BIC近似・BF視点で評価 |
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

- **正本**: `.cursor/skills` ディレクトリ
- **同期先**: `.agent/skills`（Antigravity 用）
- シンボリックリンクは使用しない

詳細な同期ルール（対象ファイル一覧、置換ルール、コマンド例）は以下を参照：

- [AGENTS.md](AGENTS.md)

### 同期対象の概要

| 種別 | 同期方法 |
|------|----------|
| スクリプト・プロンプト | `.cursor` → `.agent` へ内容完全一致でコピー |
| SKILL.md（flat-file-mysql-* 3本, mysql-table-cardinality） | `.cursor` を正本として編集後、パス置換と description 補記で `.agent` 用を派生 |
| その他スキル（questionnaire-batch-analysis, security-vulnerability-check, vcd-categorical-analysis, vcd-categorical-reporting, vcd-bayesian-evidence-analysis, mysql-er-diagram, mysql-entity-matrix, mysql-create-query-support） | `.cursor/skills` と `.agent/skills` の両方を同時更新し、内容一致を維持 |
