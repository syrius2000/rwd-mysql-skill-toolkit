created: 2026-03-01 10:28 (JST)
author: AI Agent (Gemini 2.0 Pro)

# 計画：ドキュメントの整理とアーカイブ

`docs/Artifacts` 内のファイルを、「完了した作業記録」と「今後も参照すべき開発情報」に整理し、適切なディレクトリに移動します。

## User Review Required

> [!IMPORTANT]
> 以下の分類基準で移動を行いますが、特に「今後も参照すべき情報」の移動先ディレクトリ名（`docs/Reference`）についてご確認をお願いします。

## 変更内容

### 分類と移動先

#### 1. 完了した作業（`docs/Archive` へ移動）
過去のタスク計画、実行計画、ウォークスルー、および完了したプロジェクトのサマリー。
- `Artifact_001_r_statistical_skill_implementation_0216_1200.md`
- `Artifact_002_flat_file_mysql_rebuild_plan_0216_1230.md`
- `Artifact_003_flat_file_mysql_exploration_0216_1500.md`
- `Artifact_004_implementation_summary_flat_file_mysql_0217_0030.md`
- `Artifact_005_openspec_ssd_new_chat_plan_0217_1200.md`
- `Artifact_006_openspec_ssd_initial_prompt_0217_1200.txt`
- `Artifact_007_skill_portability_openspec_theme_0221_1200.md`
- `Artifact_008_plan_ask_validation_skill_0224_1200.md`
- `Artifact_009_plan_duplicate_terminology_unique_0224_1230.md`
- `Artifact_011_verify_skill_review_scripts_0301_1100.md`
- `implementation_plan0217_0010.md`
- `walkthrough0217_0020.md`
- `walkthrough0220_1145.md`
- `walkthrough_0216_2355.md`

#### 2. 今後も参照すべき情報（`docs/Reference` へ移動）
Git操作手順や開発ルールなどの汎用的な情報。
- [git_push_rebase_procedure_0301_1030.md](../../Reference/git_push_rebase_procedure_0301_1030.md) (Git rebase 手順、旧 Artifact_010)
- `Artifact_012_cursor_agent_skills_sync_rule_0301_1200.md` (スキル同期ルール)
- `doc-coauthoring_SKILL_backup_0215_1430.md` (スキルバックアップ)

### 実施手順

1. `docs/Reference` ディレクトリを新規作成する。
2. 上記分類に従い、`mv` コマンドでファイルを移動する。
3. `docs/Artifacts` には、現在進行中の作業用ファイルのみが残る状態にする。

## 検証計画

### 確認事項
- [ ] `ls -R docs/` を実行し、ファイルが意図した場所に配置されているか確認する。
- [ ] 移動後のファイルが正常に閲覧できるか確認する。
