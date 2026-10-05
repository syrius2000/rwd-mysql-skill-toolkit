# ドキュメント索引

リポジトリルートの Markdown は **人向け**（[README.md](../README.md)）と **エージェント向け**（[AGENTS.md](../AGENTS.md)）の2本に限定する。それ以外は本ディレクトリ配下に置く。

## 配置一覧

| パス | 用途 | 主な読者 |
|------|------|----------|
| [../README.md](../README.md) | リポジトリ概要・スキル一覧・ワークフロー | 人 |
| [../AGENTS.md](../AGENTS.md) | エージェント行動ルール・正本パス・同期 | エージェント |
| [Artifacts/](Artifacts/) | 計画・実装・未着手メモ（命名は Cursor `plan-artifacts` ルール）。旧 `Artifact_*` は Archive に移行済み | 人 / エージェント |
| [Archive/](Archive/) | 完了した調査・ウォークスルー・旧計画 | 参照用 |
| [Reference/](Reference/) | 手順書・運用メモ（例: git push） | 人 |
| [Reference/evidence-analysis/](Reference/evidence-analysis/) | VCD / ベイズエビデンスの統計リファレンス（大標本・効果量） | 人 / エージェント |
| [Reference/anomaly-detection/](Reference/anomaly-detection/) | anomaly-detection の `review_note.md` / `anomaly_results.jsonl` 解釈ガイド | 人 / エージェント |
| [../sql/README.md](../sql/README.md) | Query 資産の置き場ルール | 人 / エージェント |

## Archive（過去）

テーマ別サブディレクトリ（例: `04_flat_file_mysql_skills/`）。初期設計 [1st_design.md](Archive/04_flat_file_mysql_skills/1st_design.md) は flat-file 系スキル実装前の要件メモ。
完了した計画・実装報告は以下のテーマ別ディレクトリに集約管理されている：
- [14_anomaly_detection_enhancement](Archive/14_anomaly_detection_enhancement/summary.md): EDC/RWD 異常検知スキル強化・uv移行・Score Fusion統一（2026-07）
- [15_code_understanding_and_repo_maintenance](Archive/15_code_understanding_and_repo_maintenance/summary.md): 出力隔離・README刷新・Code Understanding Suite整備（2026-07）
- [16_migrate_agent_to_agents](Archive/16_migrate_agent_to_agents/summary.md): Skill配置の標準化（.agent → .agents）および openspec 除外（2026-10）

## 新規ドキュメントの置き方

- **エージェントに常に読ませたいルール** → ルート `AGENTS.md`（短く保つ）
- **リポジトリの使い方・一覧** → ルート `README.md`
- **承認済み計画の成果物** → `docs/Artifacts/`（`{slug}_{NNN}_{MMDD}_{HHMM}.md`）
- **進行中・将来の改善案** → `docs/Artifacts/`（`backlog_*` 等の短いメモ可）
- **完了した調査記録** → `docs/Archive/<theme>/`
