# スキルリポジトリ統合 → rwd-mysql-skill-toolkit 同期 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 分散した4ローカルリポを整理し、`.agent/skills` を正本とする単一ワークツリー（`OSX_IDE_Skill_management`）に集約したうえで、GitHub 最終同期先 `syrius2000/rwd-mysql-skill-toolkit`（private）へ push する。

**Architecture:** **Fetch（リモート実態の把握）を Phase 0 で必ず実施**する。リモート toolkit はローカル `main` より進んでいる（12スキル vs 10、`mysql-create-query-support` / `vcd-bayesian-evidence-analysis` がリモートのみ）。したがって「ローカルだけを正として push」ではなく、**リモート取り込み → ローカル派生リポ（Gemini）のマージ → 正本ルール確定 → push** の順とする。Cursor 用は `.agent/skills` 正本 + `.cursor/skills` ミラー（シンボリックリンクまたは同期スクリプト）。

**Tech Stack:** git, gh, zip, Cursor/Antigravity skill ディレクトリ規約, R smoke tests

---

## 現状サマリ（2026-05-19 時点）

| ソース | `.agent/skills` 数 | 備考 |
|--------|-------------------|------|
| **rwd-mysql-skill-toolkit**（GitHub private） | **12** | 最新 push: 2026-05-13。`mysql-create-query-support`, `vcd-bayesian-evidence-analysis` あり |
| **OSX_IDE_Skill_management**（local, origin=同名リポ） | 10 | VCD 改修はあるが上記2スキル欠落 |
| **OSX_IDE_Skill_management_Gemini** | 4 | VCD + bayesian。dashboard 系。git 2026-04-12 |
| **RAW / VSCODE** | 2 | 古い VCD サブセット。同一内容 |

**結論:** 「Fetch が最初か？」→ **はい。Phase 0 は必須。** ただし push 一方向ではなく、**まず toolkit から不足スキルを取り込む**可能性が高い。

---

## ファイル構成（統合後の正）

```
OSX_IDE_Skill_management/          # ローカル作業ディレクトリ（パスは維持可）
├── .agent/skills/                  # 正本（開発・Antigravity 実行）
├── .cursor/skills/                 # Cursor ミラー（symlink 推奨）
├── sql/                            # toolkit 既存（Query 資産）
├── skill_out/
├── docs/
├── AGENTS.md                       # .agent 正本ルールに更新
├── README.md                       # toolkit README と整合
└── tests/
```

**削除対象（ZIP 後）:** `OSX_IDE_Skill_management_Gemini`, `_RAW`, `_VSCODE`

---

## Phase 0: Fetch & インベントリ（最初に実施）

### Task 0: リモート toolkit の取得と差分表作成

**Files:**
- Create: `docs/Artifacts/inventory_rwd_toolkit_vs_local_0519.md`（作業メモ）

- [ ] **Step 1: toolkit を fetch 用に clone（一時ディレクトリ）**

```bash
git clone https://github.com/syrius2000/rwd-mysql-skill-toolkit.git /tmp/rwd-mysql-skill-toolkit-fetch
cd /tmp/rwd-mysql-skill-toolkit-fetch
git log -1 --oneline
ls .agent/skills | sort > /tmp/toolkit-skills.txt
```

- [ ] **Step 2: ローカル main とスキル一覧 diff**

```bash
ls /Users/myamaguchi/Programing/OSX_IDE_Skill_management/.agent/skills | sort > /tmp/local-skills.txt
diff -u /tmp/local-skills.txt /tmp/toolkit-skills.txt
```

Expected: toolkit にのみ `mysql-create-query-support`, `vcd-bayesian-evidence-analysis`

- [ ] **Step 3: スキル単位の内容 diff（VCD 等）**

```bash
diff -rq \
  /Users/myamaguchi/Programing/OSX_IDE_Skill_management/.agent/skills/vcd-categorical-analysis \
  /tmp/rwd-mysql-skill-toolkit-fetch/.agent/skills/vcd-categorical-analysis \
  | head -30
```

- [ ] **Step 4: インベントリ MD に「取り込み元」「採用方針」列を記載**

| スキル | toolkit | local | Gemini | 採用方針 |
|--------|---------|-------|--------|----------|
| mysql-create-query-support | ○ | × | × | toolkit から取り込み |
| vcd-bayesian-evidence-analysis | ○ | × | ○ | toolkit 優先、Gemini と diff 後マージ |
| vcd-categorical-analysis | ○ | ○ | ○ | diff 表で勝者決定（下記 Task 3） |

- [ ] **Step 5: ユーザー承認**

「Phase 0 結果を確認しました。Phase 1 に進めてよい」と明示されるまで実装しない（AGENTS.md ルール）。

---

## Phase 1: ローカル作業ツリーを toolkit ベースに再構成

### Task 1: git remote の整理

**Files:**
- Modify: `/Users/myamaguchi/Programing/OSX_IDE_Skill_management/.git/config`（remote 設定）

- [ ] **Step 1: 現状確認**

```bash
cd /Users/myamaguchi/Programing/OSX_IDE_Skill_management
git remote -v
```

現状: `origin` → `OSX_IDE_Skill_management.git`

- [ ] **Step 2: toolkit を `toolkit` remote として追加**

```bash
git remote add toolkit https://github.com/syrius2000/rwd-mysql-skill-toolkit.git
git fetch toolkit
```

- [ ] **Step 3: 履歴方針を決定（ユーザーと合意）**

| 方針 | 内容 | 向き |
|------|------|------|
| **A（推奨）** | `git merge toolkit/main` で取り込み | 履歴保持・両リポ統合 |
| **B** | 作業ツリーを toolkit clone に差し替え | 単純だが旧 `OSX_IDE_Skill_management` 履歴は別管理 |

- [ ] **Step 4: 方針 A の場合 — merge**

```bash
git merge toolkit/main --no-edit
# コンフリクト時は .agent/skills を優先ルールに従い解消（Task 3 参照）
```

- [ ] **Step 5: 方針 A 後 — origin を toolkit に切替（任意・最終ゴール時）**

```bash
git remote rename origin old-osx-ide
git remote rename toolkit origin
# 確認後: git push -u origin main
```

**注意:** `origin` 切替は Phase 4（push 前）まで遅延してもよい。

---

### Task 2: Gemini / RAW / VSCODE からの取り込み

**Files:**
- Modify: `.agent/skills/vcd-categorical-analysis/`（条件付き）
- Create: `.agent/skills/vcd-bayesian-evidence-analysis/`（toolkit に無い場合のみ Gemini から）

- [ ] **Step 1: RAW / VSCODE は参照のみ（マージ不要）**

Phase 0 で差分がなければスキップ。

- [ ] **Step 2: Gemini の `vcd-bayesian-evidence-analysis`**

toolkit に既にある場合: Gemini との diff のみ記録。
toolkit に無い場合:

```bash
cp -R /Users/myamaguchi/Programing/OSX_IDE_Skill_management_Gemini/.agent/skills/vcd-bayesian-evidence-analysis \
  /Users/myamaguchi/Programing/OSX_IDE_Skill_management/.agent/skills/
```

- [ ] **Step 3: Gemini の dashboard.Rmd 等**

Phase 0 diff で「Gemini 独自の改善」と判明したファイルのみ cherry-pick または手動マージ。一括上書きしない。

- [ ] **Step 4: smoke テスト**

```bash
cd /Users/myamaguchi/Programing/OSX_IDE_Skill_management
Rscript tests/test_vcd_categorical_smoke.R
```

Expected: PASS（失敗時は Task 3 でロールバック）

- [ ] **Step 5: Commit**

```bash
git add .agent/skills/
git commit -m "chore: merge satellite repos into canonical .agent/skills"
```

---

## Phase 2: `.agent` 正本化と Cursor ミラー

### Task 3: `.agent` / `.cursor` 整合

**Files:**
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `.cursor/skills/`（symlink 化）

- [ ] **Step 1: `.agent` を正として vcd 差分を解消**

```bash
cd /Users/myamaguchi/Programing/OSX_IDE_Skill_management
# .agent を正とする場合:
rsync -a --delete .agent/skills/ .cursor/skills/
# または symlink 方式（Task 3 Step 2）
```

- [ ] **Step 2: `.cursor/skills` を symlink に（推奨）**

```bash
rm -rf .cursor/skills
ln -s ../.agent/skills .cursor/skills
```

**検証:** Cursor 再起動後、Agent で `/` → スキル一覧に 12 スキルが見えること。

**代替:** symlink が使えない環境では `scripts/sync-skills-to-cursor.sh` を追加し、コミット前に実行。

- [ ] **Step 3: AGENTS.md 更新**

```markdown
## スキル管理

- **正本**: `.agent/skills/`（開発・Antigravity 実行）
- **Cursor**: `.cursor/skills/` は正本へのミラー（symlink または同期スクリプト）。二重編集しない。
- **Git 最終同期先**: https://github.com/syrius2000/rwd-mysql-skill-toolkit
```

（「火発」→「実行」の誤字修正を含む）

- [ ] **Step 4: README.md の正本記述を AGENTS と一致**

「正本: `.cursor/skills`」→「正本: `.agent/skills`」に変更。12 スキル表を維持。

- [ ] **Step 5: Commit**

```bash
git add AGENTS.md README.md .cursor/skills
git commit -m "docs: adopt .agent/skills as canonical; mirror to .cursor"
```

---

## Phase 3: toolkit へ push（最終ゴール）

### Task 4: push 前検証とリモート反映

**Files:**
- Test: `tests/test_*.R`

- [ ] **Step 1: 全 smoke 実行**

```bash
Rscript tests/test_questionnaire_batch_smoke.R
Rscript tests/test_vcd_categorical_smoke.R
```

- [ ] **Step 2: origin が toolkit を指すことを確認**

```bash
git remote -v
# origin → rwd-mysql-skill-toolkit.git
```

- [ ] **Step 3: push**

```bash
git push origin main
```

Expected: `syrius2000/rwd-mysql-skill-toolkit` の main が更新される

- [ ] **Step 4: GitHub 上で README の 12 スキル表と一致確認**

```bash
gh repo view syrius2000/rwd-mysql-skill-toolkit --web
```

---

## Phase 4: サテライトリポのアーカイブと削除

### Task 5: ZIP アーカイブとワークスペース整理

**Files:**
- Create: `/Users/myamaguchi/Programing/archives/OSX_IDE_Skill_management_Gemini_YYYYMMDD.zip` 等

- [ ] **Step 1: archives ディレクトリ作成**

```bash
mkdir -p /Users/myamaguchi/Programing/archives
```

- [ ] **Step 2: ZIP 作成（3リポ）**

```bash
cd /Users/myamaguchi/Programing
zip -r archives/OSX_IDE_Skill_management_Gemini_$(date +%Y%m%d).zip OSX_IDE_Skill_management_Gemini
zip -r archives/OSX_IDE_Skill_management_RAW_$(date +%Y%m%d).zip OSX_IDE_Skill_management_RAW
zip -r archives/OSX_IDE_Skill_management_VSCODE_$(date +%Y%m%d).zip OSX_IDE_Skill_management_VSCODE
```

- [ ] **Step 3: Cursor マルチルート workspace から3フォルダを除外**

`Skill_Management.code-workspace` 等を編集。

- [ ] **Step 4: ユーザー確認後にディレクトリ削除**

```bash
# 確認後のみ
rm -rf OSX_IDE_Skill_management_Gemini OSX_IDE_Skill_management_RAW OSX_IDE_Skill_management_VSCODE
```

- [ ] **Step 5: 旧 origin `OSX_IDE_Skill_management` GitHub リポの扱いを決定**

| 選択肢 | 内容 |
|--------|------|
| Archive | GitHub で archive + README に toolkit へ移転と記載 |
| 削除 | 不要なら削除（慎重） |
| リダイレクト | toolkit へ統合済みなら README のみ更新 |

---

## リスクと回避

| リスク | 回避 |
|--------|------|
| ローカルだけ push して toolkit の新スキルを上書き | **Phase 0 Fetch 必須** |
| Cursor が `.agent` を読まない | `.cursor/skills` symlink 維持 |
| symlink が Windows / 一部 FS で失敗 | `scripts/sync-skills-to-cursor.sh` をフォールバック |
| Gemini の dashboard と main の report.Rmd 競合 | Phase 0 diff で明示的に勝者決定 |
| private repo の 404（Web Fetch） | `gh` / `git clone` を使用 |

---

## 未決事項（実装前に1行で回答）

1. **履歴方針:** merge（A）か clone 差し替え（B）か？
2. **VCD レポート出力:** main の `report.Rmd` と Gemini の `dashboard.Rmd` のどちらを正とするか？
3. **ローカルフォルダ名:** `OSX_IDE_Skill_management` のままか、`rwd-mysql-skill-toolkit` にリネームするか？
4. **旧 `OSX_IDE_Skill_management` GitHub リポ:** archive か削除か？

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-19-skill-repo-consolidation-rwd-mysql-toolkit.md`.**

**Two execution options:**

1. **Subagent-Driven (recommended)** — タスクごとにサブエージェント、タスク間レビュー
2. **Inline Execution** — このセッションで Phase 0 から順に実行（チェックポイントで承認）

**Which approach?**

**最初の一手:** Phase 0 Task 0（`git clone` + diff）のみ実行してインベントリ MD を提示 → 承認後 Phase 1 へ。
