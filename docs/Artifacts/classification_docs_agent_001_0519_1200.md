# docs / .agent 整理 分類表

created: 2026-05-19 12:00 (JST)
author: Composer

## superpowers

| ファイル | 判定 | 備考 |
|----------|------|------|
| specs/vcd-skills-rebuild-specification.md | keep_superpowers | VCD 要求正本 |
| specs/2026-04-04-vcd-skill-improvement-design.md | keep_superpowers | 設計正本 |
| backlog/skill-improvement-backlog.md | keep_superpowers | |
| plans/2026-05-13-integrated-db-analysis-skills.md | keep_superpowers | 進行中 |
| plans/2026-05-19-skill-repo-consolidation-rwd-mysql-toolkit.md | keep_superpowers | 本整理完了後に Archive へ |
| plans/2026-04-04-vcd-skill-improvement.md | move_archive | 実装済み（スキル存在）。証跡として Archive/12 へ |

## Archive

| ファイル | 判定 | 備考 |
|----------|------|------|
| 12/.../2026-04-04-vcd-skill-improvement-design.md | delete_duplicate | 正本は superpowers/specs（内容差あり・古い版） |
| 12/integrated_db_analysis_skills_merge_message_2026-05-13.md | move_archive | → 13_integrated_db_analysis/ |
| 12/questionnaire_margin_table_namespace_2026-05-13.md | move_archive | → 13_integrated_db_analysis/ |
| 09/*, 10/* | fix_link_only | Artifact_010 → Reference、Artifact_001 ER → Archive/10 |
| 12/summary.md, audit_report_agent_skills_0404.md | fix_link_only | 10→13 スキル注記、設計書リンク |

## .agent

| 項目 | 判定 |
|------|------|
| .agent/shared/ | git add（正本） |
| .agent/skills/shared/ | git rm |
| .agent/skills → .cursor/skills | rsync --delete |
