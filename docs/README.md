# ドキュメント索引

リポジトリルートの Markdown は **人向け**（[README.md](../README.md)）と **エージェント向け**（[AGENTS.md](../AGENTS.md)）の2本に限定する。それ以外は本ディレクトリ配下に置く。

## 配置一覧

| パス | 用途 | 主な読者 |
|------|------|----------|
| [../README.md](../README.md) | リポジトリ概要・スキル一覧・ワークフロー | 人 |
| [../AGENTS.md](../AGENTS.md) | エージェント行動ルール・正本パス・同期 | エージェント |
| [superpowers/](superpowers/) | 現行の設計・実装計画・再構築仕様 | エージェント / 開発者 |
| [superpowers/backlog/](superpowers/backlog/) | 未着手のスキル改善メモ | 開発者 |
| [Artifacts/](Artifacts/) | 計画・実装・TODO の成果物（命名は Cursor `plan-artifacts` ルール）。旧 `Artifact_*` は Archive に移行済み | 人 / エージェント |
| [Archive/](Archive/) | 完了した調査・ウォークスルー・旧計画 | 参照用 |
| [Reference/](Reference/) | 手順書・運用メモ（例: git push） | 人 |
| [Reference/evidence-analysis/](Reference/evidence-analysis/) | VCD / ベイズエビデンスの統計リファレンス（大標本・効果量） | 人 / エージェント |
| [../sql/README.md](../sql/README.md) | Query 資産の置き場ルール | 人 / エージェント |

## superpowers（現行）

- [superpowers/README.md](superpowers/README.md) — VCD 系の入口
- `specs/` — 要求・設計の正本に近い文書
- `plans/` — チェックリスト付き実装計画

## Archive（過去）

テーマ別サブディレクトリ（例: `04_flat_file_mysql_skills/`）。初期設計 [1st_design.md](Archive/04_flat_file_mysql_skills/1st_design.md) は flat-file 系スキル実装前の要件メモ。

## 新規ドキュメントの置き方

- **エージェントに常に読ませたいルール** → ルート `AGENTS.md`（短く保つ）
- **リポジトリの使い方・一覧** → ルート `README.md`
- **承認済み計画の成果物** → `docs/Artifacts/`（`{slug}_{NNN}_{MMDD}_{HHMM}.md`）
- **進行中・将来の改善案** → `docs/superpowers/backlog/` または `docs/superpowers/plans/`
- **完了した調査記録** → `docs/Archive/<theme>/`
