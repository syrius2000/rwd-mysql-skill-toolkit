created: 2026-02-17 12:00 JST
author: AI Agent (LLM Model)

# OpenSpec 型 SSD 開発・新チャット実施計画

新チャット起動時に「何をどう依頼するか」を一文で渡し、以降は /opsx-* の順序と各ステップのプロンプト案に従う。

---

## 1. 新チャット起動時の初期プロンプト案（コピペ用）

別ファイル `Artifact_006_openspec_ssd_initial_prompt_0217_1200.txt` に同じ内容を格納。チャットの**最初のメッセージ**として貼る。

- 成果物に Cursor の Agent Skill を含める場合は、[公式](https://cursor.com/ja/docs/context/skills)準拠。スクリプトは `scripts/` 配下、SKILL.md からはスキルルート相対パスで参照。必要に応じて `references/`、`assets/` を使う。
- Skill の作成・修正では skill-creator（create-skill）に従う。description は第三者視点で WHAT/WHEN、SKILL.md は要点に絞り、詳細は references/ 等に分離。
- Artifact は `./docs/Artifacts` に保存し、ファイル名は連番（3桁ゼロパディング）と日時（MMDD_HHMM）を含める。
- change 名（kebab-case）を末尾に記載する。

---

## 2. /opsx-* の実行順序（フロー）

| 順序 | コマンド | 役割 |
|------|----------|------|
| 1 | `/opsx-new-change` | change 名で `openspec/changes/<name>/` をスキーマ付きで作成。最初のアーティファクト（proposal）の指示を表示。 |
| 2 | `/opsx-continue` を繰り返す **または** `/opsx-ff-change` | proposal → design → specs → tasks を順に作成。 |
| 3 | `/opsx-apply` | tasks.md のタスクを実装。CLI や Skill の scripts/ もここで実装。 |
| 4 | `/opsx-sync`（任意） | delta specs を main specs（openspec/specs/）に反映。 |
| 5 | `/opsx-archive` | 完了した change を `openspec/changes/archive/YYYY-MM-DD-<name>/` に移動。 |

---

## 3. 各段階で与えるプロンプト案

### 3.1 起動後すぐ（change 作成）

「`/opsx-new-change` で change 名は `<my-change-name>`。spec-driven のまま。」

### 3.2 アーティファクト作成（continue または ff）

**選択 A: 1 つずつ（/opsx-continue）**

- 1 回目: 「`/opsx-continue` で proposal を書いて。Why / フロー概要 / What Changes / Capabilities（New・Modified）/ Impact を含める。Skill を成果物にする場合は、Cursor 公式の scripts/・references/ 構成と skill-creator に従う旨を proposal に一言書いて。」
- 2 回目以降: 「`/opsx-continue` で次アーティファクトを作成して。」

**選択 B: 一括（/opsx-ff-change）**

「`/opsx-ff-change` で proposal から tasks まで一括作成して。Skill を含む場合は design/tasks で、Cursor 公式（scripts/ references/）と skill-creator 準拠を前提に書いて。」

### 3.3 design / tasks に書く Skill 前提（プロンプトに含める文言例）

- design.md: 「Skill は `.cursor/skills/<skill-name>/` に `SKILL.md` と `scripts/`（必要なら `references/`）を置く。スクリプトはスキルルート相対パスで参照する。」
- tasks.md: 「skill-creator に従い、SKILL.md は 500 行以内、description は WHAT/WHEN、実行スクリプトは scripts/ に配置。」

### 3.4 実装（apply）

「`/opsx-apply <change-name>` でタスクを実装して。Skill のスクリプトは必ず `scripts/` 配下に作成し、SKILL.md では `scripts/xxx.sh` のように相対パスで参照すること。」

### 3.5 同期（任意）

「delta specs を main に反映したい。`/opsx-sync <change-name>` を実行して。」

（アーカイブ済みの場合は「アーカイブ内の `openspec/changes/archive/YYYY-MM-DD-<name>/specs/` を main に sync して」と指定。）

### 3.6 アーカイブ

「`/opsx-archive <change-name>` でアーカイブして。実施サマリは docs/Artifacts に Artifact_XXX_... で保存して。」

---

## 4. 参照・制約

| 参照 | 内容 |
|------|------|
| [Cursor スキル公式](https://cursor.com/ja/docs/context/skills) | SKILL.md 必須。任意で scripts/、references/、assets/。スクリプトはスキルルート相対パスで参照。 |
| skill-creator (create-skill) | description は第三者・WHAT/WHEN、SKILL.md 簡潔・500 行目安、スクリプトは scripts/、実行方法を SKILL.md に明記。 |
| ワークスペースルール | Artifact は ./docs/Artifacts、連番（3桁ゼロパディング）と日時（MMDD_HHMM）。TODO/PLAN は承認後に実行。 |

---

## 5. 想定タイムライン（目安）

1. 新チャット開始 → 初期プロンプト貼り付け（change 名を埋める）
2. /opsx-new-change → change 作成、最初のアーティファクト指示確認
3. /opsx-continue 複数回 または /opsx-ff-change → proposal / design / specs / tasks 作成
4. /opsx-apply → 実装（Skill は scripts/ 構成で）
5. /opsx-sync（任意）→ /opsx-archive → サマリを docs/Artifacts に保存
