# 統合DB構築・分析スキル管理リポジトリ

このリポジトリは、ローカル CSV やフラットファイルから RDBMS を構築し、MySQL/MariaDB 上で探索・Query作成・分析用データセット抽出を行い、R/R Markdown による分析へつなぐための **統合DB構築・分析スキル** を管理します。

## このリポジトリのゴール

このリポジトリは、単に CSV を MySQL に投入するためだけの道具ではありません。大規模な大学講座や小規模プロジェクトの手元データから RDBMS を作り、構造を確認し、必要な Query を作り、分析可能なデータセットへ整える経験を若手へ引き継ぐための Skill 群です。

会社の大規模で整備済みの DB だけを使ってきた人でも、以下の流れを自分で辿れることを目標にします。

1. CSV / flat files から DB を作る
2. ER 図、dictionary、cardinality、entity matrix で DB を探索する
3. 自然文の分析目的を SQL に落とす
4. 本 SQL と検証 SQL を保存し、再利用可能な資産にする
5. R / R Markdown の分析・レポートへ渡す

## リポジトリ構造

```
├── .agent/
│   ├── skills/             # スキル正本
│   └── shared/             # R ユーティリティ（run_scope.R 等）
├── docs/
│   ├── README.md           # ドキュメント索引（配置ルール）
│   ├── Artifacts/          # 計画・実装・未着手メモ（plan-artifacts 命名）
│   ├── Reference/          # 手順書・運用メモ
│   ├── Archive/            # 完了した調査・旧計画
├── skill_out/              # スキル実行の生成物
├── sql/                    # Query作成支援で作成したSQL資産
├── AnotherPJ/              # 補助プロジェクト
├── flat_file_mysql/        # フラットファイル MySQL 関連資産
└── tests/                  # テスト
```

## 使い方（最短）

- **スキル定義**: 各スキル配下の `SKILL.md`
- **実行用テンプレ**: 各スキル配下の `templates/`（R / Rmd / Python 等）
- **出力先**: 原則 `./skill_out/` 配下（スキルごとにサブディレクトリ）

例: `questionnaire-batch-analysis`（テストデータ）

```bash
Rscript tests/test_questionnaire_batch_smoke.R
open tests/skill_out_smoke/q01_gender_dept/report.html
```

## Query 作成支援

`mysql-create-query-support` は、若手が「こういう患者群を抽出したい」「このイベントを数えたい」と自然文で相談したときに、SQL作成を段階的に支援する Skill です。

この Skill は、いきなり完成 SQL を作りません。まず分析目的を、対象、イベント、曝露、アウトカム、属性、期間、除外条件、データセットの粒度に分解します。そのうえで、利用可能な ER 図、dictionary CSV、cardinality 結果、entity matrix 結果を参照し、必要なテーブル・カラム・JOIN キーを特定します。

既存成果物がない場合は、`SHOW TABLES`、`DESCRIBE <table>`、`INFORMATION_SCHEMA.COLUMNS` などで Table Schema を確認してから SQL を設計します。スキーマ確認なしに本 SQL は作りません。

標準成果物は repo root の `sql/` 配下に置きます。

```text
sql/drafts/<topic>/
  main_query.sql
  validation_query.sql
  query_note.md
```

検証済みになった SQL は、ユーザー確認後に `sql/validated/<topic>/` へ移します。

## カテゴリ分析・エビデンス（VCD）

Pass 0 検分のあと、各分析スキルの 3ステップ（R 計算 → AI 考察 → ダッシュボード）で完結する。
大標本（N > 2,000）では P 値だけでは実務判断できない（飽和問題）。

VCD 系と `questionnaire-batch-analysis` は [agentic-evidence-analysis](https://github.com/syrius2000/agentic-evidence-analysis) を正本として参照し、このリポジトリでは利用案内と周辺ドキュメントを保つ。共通契約として `.agent/shared/analysis_quality_contract.md` を参照し、Pass 2 のあとに必要なら `quality_check.md`、複数設問では `cross_question_summary.md` を追加する。

| 指標 | 目安 | 意味 |
|------|------|------|
| Evidence Score | r² − k·log(N) > 0 | セル単位の信号 |
| Bayes Factor BF₁₀ | > 100（目安） | 関連モデルの優位 |
| Cramér's V | > 0.1（Cohen 目安） | 実務的関連の強さ |

2016年にアメリカ統計学会（ASA）が発表した「p値に関する声明」の要点を以下に示します。
- **p値は「仮説（偶然）とデータの矛盾度」を示す数字である**: p値とは、調べたい差が「全くない（偶然である）」と仮定したときに、そのデータ（またはそれ以上に極端なデータ）が得られる確率のことであり、それ以上の意味はありません。
- **p値は「研究（ビジネス）の重要性」を証明しない**: p値がどれだけ小さくても（例：$p < 0.001$）、その差がビジネスや科学において「実務的に価値があるほど大きいか」は判断できません（飽和問題がこれに該当します）。
- **「$p < 0.05$ かどうか」だけで白黒つけてはいけない**: p値が $0.05$ を下回ったからといって「大発見だ」と結論づけたり、上回ったからといって「差がない、無価値だ」と全否定するような、思考停止の二択評価はやめるべきです。

### 数理・統計 Reference

| テーマ | 入口 | 推奨用途 |
|---|---|---|
| カテゴリカル分析の基礎 | `docs/Reference/evidence-analysis/stats_categorical.md` | 期待度数、Pearson residual、Cramér's V / Fei、大標本での P 値飽和を確認する |
| ベイズ的エビデンス | `docs/Reference/evidence-analysis/stats_bayesian.md` | BF10、Evidence Score、EBIC/BIC ペナルティの意味を確認する |
| 実務的な深掘り | `docs/Reference/evidence-analysis/advanced_analysis.md` | 効果量、セル単位エビデンス、層別の優先順位を決める |
| AI 考察文 | `.agent/skills/vcd-categorical-analysis/references/ai-narrative-workflow.md` | 残差、効果量、層別差を過剰主張せず説明する |
| 異常検知結果の解釈 | `docs/Reference/anomaly-detection/anomaly_results_interpretation.md` | `review_note.md` / `anomaly_results.jsonl` のスコア、ラベル、確認順序を読む |

- 例データ: `examples/data/titanic.csv`, `examples/data/ucb_admissions.csv`
- 研修用プロンプト: `examples/prompt/`
- `vcd-categorical-analysis`: **3ステップ**（R 2パス → `executive_summary.md` → `dashboard.Rmd`）
- `vcd-categorical-reporting`: **非推奨**（Step 2 に統合）

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
| 分析系 | `vcd-pass0-consultation`, `questionnaire-batch-analysis`, `vcd-categorical-analysis`, `vcd-bayesian-evidence-analysis`, `anomaly-detection` | データ検分・抽出結果の分析・異常検知・レポート化（`vcd-categorical-reporting` は非推奨） |
| 保守系 | `security-vulnerability-check` | スクリプトとSQL支援の安全性を確認する |

## 管理スキル一覧

新規作成・修正・レビュー・検証は `.agent/skills/<skill-name>/` を対象にします。

| スキル名 | 概要 |
|---|---|
| `flat-file-mysql-overview` | CP932 CSV → MySQL 投入の全体像（Step 1→2→3） |
| `flat-file-mysql-ddl-generation` | CP932 CSV から DDL 用サンプル SQL とレコード数・重複数レポート（Step 1） |
| `flat-file-mysql-load-validation` | 完成版 SQL 作成支援・DB 実行・件数比較（Step 2〜3） |
| `mysql-er-diagram` | DB メタから辞書 CSV / Draw.io XML / PlantUML の ER 図生成 |
| `mysql-table-cardinality` | 総行数・カラム濃度数（cardinality）を CSV/JSON 出力 |
| `mysql-entity-matrix` | 特定 ID の全テーブル存在フラグ `[1,0]` マトリックス SQL 生成 |
| `mysql-create-query-support` | 自然文の分析目的から探索 SQL・本 SQL・検証 SQL・query note（`sql/` 配下） |
| `vcd-pass0-consultation` | カテゴリ分析前のデータ検分・次元選定（bayesian / questionnaire 前段） |
| `questionnaire-batch-analysis` | 設問設定 CSV で `nominal_2way` / `likert_2way` / `nominal_3way` を一括処理、`summary.csv` と設問別 HTML、必要に応じて `cross_question_summary.md` |
| `vcd-categorical-analysis` | 2-way/3-way 名義カテゴリ。**3ステップ**（R 2パス集計 → `executive_summary.md` → `quality_check.md` → `dashboard.Rmd`） |
| `vcd-categorical-reporting` | **非推奨**（analysis Step 2 に統合。参照テンプレのみ） |
| `vcd-bayesian-evidence-analysis` | 大標本 2-way/3-way。**3-Pass**（`evidence_results.json` → `executive_summary.md` → `quality_check.md` → `dashboard.html`） |
| `anomaly-detection` | EDC/RWD データの異常候補をルール、ロバスト統計、Isolation Forest、LOF で順位付けし、素人にも読めるレビュー文書へつなぐ |
| `security-vulnerability-check` | ソースコードの脆弱性チェック（SQLi / OS コマンド / パストラバーサル等） |

## テスト

R ベースの smoke テストと Python pytest があります（`tests/test_*.R`, `tests/test_*.py`）。例:

```bash
Rscript tests/test_questionnaire_batch_smoke.R
Rscript tests/test_vcd_categorical_smoke.R
pytest tests/test_mysql_create_query_support_assets.py
```

## 生成物（例）

- `questionnaire-batch-analysis`: `tests/skill_out_smoke/`（テスト実行時に生成）
- `vcd-categorical-analysis`: `skill_out/vcd_categorical_test/`（テスト実行例）

## 管理ルール

- **正本**: `.agent/skills` ディレクトリ
- **廃止**: `.cursor/skills` は旧規格のため管理対象外
- SQL成果物は Skill 配下に置かず、repo root の `sql/` に置く

## ドキュメント

| ファイル | 役割 |
|----------|------|
| [README.md](README.md) | 本ファイル（人向けの入口） |
| [AGENTS.md](AGENTS.md) | Codex / Antigravity 等のエージェント向けルール（**編集時は機能を壊さない**） |
| [docs/README.md](docs/README.md) | `docs/` 配下の索引・新規文書の置き場 |
