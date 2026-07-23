# 開発ルール

- **環境**: Mac mini M2 Pro / Ubuntu 24 LTS / QNAP TS-464
- **DB**: MySQL 8.4（Mac）、MariaDB（QNAP `192.168.0.110:3307`）
- **領域**: 薬学、統計、RWD、医薬品安全性・有効性
- **ロケール**: 日本語、日付・時刻はJST

## 基本ルール

- 回答は日本語で簡潔にし、根拠ファイルと行番号を示す
- TODO/PLANは「実行して」と明示されるまで実装しない。レビューのみは承認ではない
- 大規模変更は `docs/Artifacts/` に実装計画を作り、承認後に着手する
- 既存の無関係な変更は戻さず、コミットにも混ぜない
- APIキー、パスワード、PHI/PIIをハードコードまたは成果物へ複製しない
- DB操作は接続先を確認し、明示承認なしに更新系SQLを実行しない
- 失敗時: 原因と次のアクションを簡潔に示す

## ドキュメント

- ルートMarkdownは `README.md` と `AGENTS.md` のみ
- 計画・作業メモは `docs/Artifacts/`、過去記録は `docs/Archive/`
- 索引と命名規約は [docs/README.md](docs/README.md)
- Skill成果物は各Skillの契約に従い、原則 `skill_out/` に保存

## コーディング

- UTF-8 / LF。入力がCP932の場合は境界で明示的に変換する
- 複雑なロジック・データフローはMermaidで可視化する
- macOSとUbuntuで動く可搬な実装を優先する
- 不要になったコードは削除する
- BSD/GNU差があるコマンドはPOSIX準拠を優先する

## スキル管理

```text
.agent/
├── skills/<skill-name>/   # Skill正本
└── shared/                # 共通契約とR/Pythonユーティリティ
```

- 正本は `.agent/skills/<skill-name>/`。`.cursor/skills/` は復活させない
- **編集対象**: `SKILL.md`, `Reference.md`, `references/`, `templates/`, `scripts/`, `tests/`
- `.agent/shared/` の `analysis_quality_contract.md`, `inspect_data.R`, `run_scope.R`, `run_scope.py` は現行Skillの必須依存
- 同一Skillの再実行は `run_<id>/` に隔離し、既存成果物を上書きしない
- リポジトリ外の汎用Skillは追跡しない。追跡済みの `grilling`, `teach`, `writing-great-skills` は管理対象

## コード理解

- `code-understanding-pro`: 親Skill。モード選択、成果物、チャット要約を所有
- `code-understanding-pyramid`: 5段階理解フレーム。独自成果物を作らない
- `stats-sql-comprehension`: SQL・統計アダプター。親レポートへ結果を返す
- Quick Modeはチャットのみ。それ以外は `report.md`, `run_meta.json`, `source_manifest.json` を `skill_out/code_understanding/<target>/run_<id>/` に保存
- 契約変更時は `code-understanding-pro/references/interface.md` と `interface_version` を同期する

## SQL・分析

- `mysql-create-query-support` のSQLは `sql/drafts/` から `sql/validated/` へ進める
- 標準SQL成果物は `main_query.sql`, `validation_query.sql`, `query_note.md`
- カテゴリカル分析系5スキルの恒久正本は `agentic-evidence-analysis`。本リポジトリは統合・検証用ミラー
- `vcd-categorical-analysis` はR計算、`executive_summary.md`、`dashboard.Rmd` を完遂する
- `vcd-bayesian-evidence-analysis` もPass 1から3まで途中停止せず完遂する
- `vcd-categorical-reporting` は非推奨
