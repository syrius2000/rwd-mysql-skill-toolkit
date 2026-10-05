# アーカイブサマリー: Skill配置標準化（.agent → .agents 移行）および openspec 除外

- **対象期間**: 2026-10-05 (JST)
- **ステータス**: 完了 (Owner条件付き受入: accepted-with-risk)
- **テーマID**: 16_migrate_agent_to_agents
- **作成日**: 2026-10-05 JST

---

## 1. 対象と結論

### 対象
本テーマは、Antigravity 規格に適合させるためのワークスペース設定ディレクトリの移行（旧規格 `.agent/` から現行規格 `.agents/` への移動）、リポジトリ内外のパスリファレンス置換、外部開発支援フレームワーク（OpenSpec）の自動生成ファイル群の `.gitignore` による追跡除外、および一連の検証・QMS対応（`impl-plan-009-migrate-agents`）を対象とする。

### 結論
- **ディレクトリ移行**: 独自管理 14 Skill および `shared/` を `git mv` により `.agents/` へ移動し、Git 履歴を保持したまま旧 `.agent/` を完全消去した。
- **.gitignore 調整**: `.agents/skills/openspec-*/`（12件）、`.agents/skills/.openspec-target`、`.agents/workflows/`（12件）を Git 管理から除外し、本リポジトリ固有資産のみを追跡対象とした。
- **リファレンス置換**: `AGENTS.md`、`README.md`、各種 `SKILL.md`（10件）、テストスクリプト（16件）、実例プロンプト等に含まれる `.agent/` 表記を `.agents/` に完全置換した。
- **品質ループ完了**: QMS Loop（`impl-plan-009-migrate-agents`）において、Finding（F-009-01〜04）の修正、Reviewer 独立検証（remediated）、および Owner 裁定（accepted-with-risk）を経て正式にクローズ（terminal）した。

---

## 2. 確定した決定と理由

1. **歴史的アーカイブの保持**:
   - *決定*: `docs/Archive/`、`openspec/changes/archive/` 等の凍結記録文書は、作成当時の歴史的事実を保持するため `.agent` 参照を改変せず維持した。
2. **OpenSpec 関連資産の追跡除外**:
   - *決定*: OpenSpec 自動生成物（`skills/openspec-*`, `workflows/`）は本リポジトリのスコープ外とし、`.gitignore` で除外した。
3. **Owner 裁定条件（Conditions）の遵守**:
   - コミット前に openspec 関連が追跡対象に入っていないことを再確認する（検証済み）。
   - 汎用Skillは `~/.agents` またはプラグインに置き、リポジトリの `.agents/skills` へ置かない。
   - 必要なら後日 `.gitignore` のレガシー `.agent/` 行を別計画で整理する。

---

## 3. 主要成果と検証の限界

### 主要成果
- **検証マトリクス T-1〜T-6 全件合格**:
  - T-1 (Git追跡状態): openspec 除外、14 Skill + shared の移動認識確認
  - T-2 (`test_skill_frontmatter.py`): 14 Skill frontmatter 正常
  - T-3 (`test_analysis_quality_contract_docs.py`): 品質契約参照パス正常
  - T-4 (`test_mysql_create_query_support_assets.py`): クエリアセット正常
  - T-5 (`test_run_scope.py`): 共通実行スコープテスト正常
  - T-6 (稼働資産内の残存参照検索): ヒット 0 件

### 残余リスク（Owner 裁定より）
- **RR-009-01**（尤度: low, 影響度: medium）: 承認前の作業ツリー変更先行リスク（計画承認後実装の徹底により緩和）。
- **RR-009-02**（尤度: low, 影響度: low）: 汎用Skillの誤配置がGit追跡されるリスク（コミット前レビューで差分検知により除外）。

---

## 4. 未解決事項と引継ぎ

- すべての実装・検証・QMS審査は完了しており、作業ツリー変更の一括コミット作成のみを残す。

---

## 5. 元文書と復元情報

| 元文書パス | 役割・種別 | 完了日付 (JST) | 復元元 |
|---|---|---|---|
| `docs/Artifacts/implementation_plan_009_1005_migrate_agent_to_agents.md` | 実装計画書（QMS連携） | 2026-10-05 | 作業ツリー / Git |
| `docs/Artifacts/qms-cases/impl-plan-009-migrate-agents/` | QMS 監査記録正本（case.json） | 2026-10-05 | `docs/Artifacts/qms-cases/` に保持 |
