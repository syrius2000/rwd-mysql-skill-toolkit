# 環境

- **環境**: MAC mini(M2PRO, 32G), Ubuntu 24 LTS / QNAP TS-464(21T RAID5)
- **技術**: R, Python, SQL, C++ / vim, Antigravity, CURSOR / MySQL 8.4 (Mac), MariaDB (QNAP 192.168.0.110:3307)
- **専門**: 薬学・統計（ベイズ・ML、RWD）、医薬品安全性・有効性の調査・試験
- **ロケール**: 日本在住. 日付は JST で報告

## 基本ルール

- 回答は必ず**日本語**。推論・思考は英語
- TODO/PLAN: 「実行して」と明示されるまで実行しない。レビューのみでは承認不可
- 段階的承認: 大規模変更前は `implementation_plan.md` を作成し、承認を得ること
- 疑問・アドバイスは簡潔・具体・選択肢付きで。曖昧時は1〜2行で確認
- 出力は簡潔に。コードコメントは最小限
- 失敗時: 原因と次のアクションを簡潔に示す
- APIキー・パスワードはハードコードしない
- 参照: 根拠となるコード・ファイル・行番号を明示

## Artifacts & ドキュメント

- Skill の成果物・指示書は各 Skill の指示に従う（一般的には `./skill_out` 配下など）。
- **ルートの Markdown**: 本ファイル（エージェントルール）と `README.md`（人向け概要）のみ。それ以外は `docs/` 配下（索引は [docs/README.md](docs/README.md)）。
- **計画成果物**: `./docs/Artifacts/`（Cursor `plan-artifacts` の命名・先頭メタ行に従う）。
- **現行設計・計画**: `./docs/superpowers/`。未着手改善は `./docs/superpowers/backlog/`。
- **過去記録**: `./docs/Archive/`。

## コーディング

- UTF-8 / LF。CP932/CRLF は即時変換
- ロジック・データフローは Mermaid を積極利用
- M2 PRO / Ubuntu を前提にしたコード
- 不要になったコードは削除する
- macOS/Ubuntu: BSD vs GNU の差異に注意。`sed -i` 等は実行前にチェック。GNU版（Homebrew）優先、不明時は POSIX 準拠で可搬性を確保

## スキル管理

### `.agent/` 構成

`.agent/skills/<skill-name>/` が唯一のスキル正本です。旧ミラー（`.cursor/skills/`）は廃止済みなので、復活させないでください。

```text
.agent/
├── skills/<skill-name>/   # 正本（SKILL.md, references/, templates/, ...）
└── shared/                # R ユーティリティ（スキルではない）
```

- **正本**: `.agent/skills/<skill-name>/`
- **編集対象**: `SKILL.md`, `Reference.md`, `references/`, `templates/`, `scripts/`, `tests/`
- **R ユーティリティ**: `.agent/shared/`（`run_scope.R`, `inspect_data.R`）
- **Reference.md**: `.agent/skills/<name>/Reference.md` のみ編集
- **契約の正本**: `references/interface.md`（変更時は `interface_version` を整合させる）。
- **VCD 系**: `vcd-pass0-consultation` は分析前の検分。`vcd-categorical-analysis` は **3ステップ必須**（Step1 内で R `--profile` → `render_config.json` → `--render`、Step2 `executive_summary.md`、Step3 `dashboard.Rmd` 既定）。`vcd-categorical-reporting` は非推奨。
- **複雑分析**: `vcd-bayesian-evidence-analysis` も実行フェーズでは Pass 1→2→3 を途中停止せず完遂する。

## 統合方針

- このリポジトリは統合DB構築・Query作成支援の本体として扱う。
- カテゴリカル分析・エビデンス分析の同名5スキルは [agentic-evidence-analysis](https://github.com/syrius2000/agentic-evidence-analysis) を正本とし、ここでは案内と補助資産を保つ。

## Query 作成支援

- 自然文から SQL を作る `mysql-create-query-support` を探索系に置く。
- SQL 成果物は repo root の `sql/` に保存（`sql/drafts/` → 検証後 `sql/validated/`）。
- 標準: `main_query.sql`, `validation_query.sql`, `query_note.md`。
