# 開発ルール

- **環境**: Mac mini M2 Pro / Ubuntu 24 LTS / QNAP TS-464
- **DB**: MySQL 8.4（Mac）、MariaDB（QNAP `192.168.0.110:3307`）
- **領域**: 薬学、統計、RWD、医薬品安全性・有効性
- **ロケール**: 日本語、日付・時刻はJST

## リポジトリの責務

このリポジトリは、DB固有Skillの正本であり、RWDデータワークフローの実行・統合ハブである。

| 領域 | 正本・扱い |
|---|---|
| DB固有Skill、RWD実行フロー、統合テスト | このリポジトリで管理する |
| 汎用コード理解・開発支援Skill | [Productivity-Skill](https://github.com/syrius2000/Productivity-Skill)を正本とし、ここへ追跡コピーを置かない |
| VCD・統計的エビデンス分析Skill | [agentic-evidence-analysis](https://github.com/syrius2000/agentic-evidence-analysis)を正本とし、ここでは統合・検証用ミラーを扱う |

Productivity-Skillの導入コマンド:

```bash
npx skills add syrius2000/Productivity-Skill
```

ローカル管理Skillは`.agents/skills/`配下に置く。DB・RWD・統計系の14件と、OpenSpec変更管理用の`openspec-*`12件である。

```text
anomaly-detection
flat-file-mysql-ddl-generation
flat-file-mysql-load-validation
flat-file-mysql-overview
mysql-create-query-support
mysql-entity-matrix
mysql-er-diagram
mysql-table-cardinality
questionnaire-batch-analysis
security-vulnerability-check
vcd-bayesian-evidence-analysis
vcd-categorical-analysis
vcd-categorical-reporting
vcd-pass0-consultation
openspec-* (12件)
```

`code-understanding-pro`、`code-understanding-pyramid`、`stats-sql-comprehension`、`teach`、`writing-great-skills`、`grilling`は外部汎用Skillであり、ローカル管理一覧に含めない。

## 基本ルール

- 回答は日本語で簡潔にし、根拠ファイルと行番号を示す。
- 依頼された作業は、確認を挟まず完了まで進める。途中の前提や判断は最終報告で明示する。
- 大規模変更は`docs/Artifacts/`に計画書を残してから進める（計画書は記録であり、承認待ちには使わない）。
- 承認が必要なのは、DB更新系SQLの実行、外部システムへの書き込み、本番相当データの変更のみ。
- 既存の無関係な変更は戻さず、コミットにも混ぜない。
- APIキー、パスワード、PHI/PIIをハードコードまたは成果物へ複製しない。
- DB操作は接続先を確認し、明示承認なしに更新系SQLを実行しない。
- 失敗時は原因と次のアクションを簡潔に示す。

## ドキュメントと成果物

- ルートMarkdownは`README.md`と`AGENTS.md`のみ。
- 計画・作業メモは`docs/Artifacts/`、過去記録は`docs/Archive/`に置く。
- 索引と命名規約は[docs/README.md](docs/README.md)に従う。
- Skill成果物は各Skillの契約に従い、原則`skill_out/`に保存する。

## Skillと共有資産

```text
.agents/
├── skills/<skill-name>/   # ローカル管理Skill
└── shared/                # 共通契約とR/Pythonユーティリティ
```

- `.agents/shared/analysis_quality_contract.md`、`.agents/shared/inspect_data.R`、`.agents/shared/run_scope.R`、`.agents/shared/run_scope.py`は現行Skillの必須依存であり、移動・削除しない。
- 同一Skillの再実行は`run_<id>/`へ隔離し、既存成果物を上書きしない。
- SQL成果物はSkill配下ではなく`sql/`に保存する。
- `mysql-create-query-support`のSQLは`sql/drafts/`から`sql/validated/`へ進める。標準成果物は`main_query.sql`、`validation_query.sql`、`query_note.md`である。

## 実装

- UTF-8 / LF。入力がCP932の場合は境界で明示的に変換する。
- 複雑なロジック・データフローはMermaidで可視化する。
- macOSとUbuntuで動く可搬な実装を優先する。
- 不要になったコードは削除する。
- BSD/GNU差があるコマンドはPOSIX準拠を優先する。
