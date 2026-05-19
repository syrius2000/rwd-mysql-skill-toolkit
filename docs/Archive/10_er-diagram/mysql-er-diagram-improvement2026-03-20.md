# mysql-er-diagram スキル改修 実装プラン

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 設計 Artifact_001 に基づき、辞書フル再生成・Draw.io スタイル固定・`.agent/skills` 正本と `scripts/sync-cursor-skills.sh` によるミラーを行う。

**Architecture:** スクリプトは `.agent/skills/mysql-er-diagram/` を改修し、同期スクリプトで `.cursor/skills/` に反映する。

**Tech Stack:** Python 3（標準ライブラリのみ）, CSV, xml.etree.ElementTree, MySQL INFORMATION_SCHEMA

**参照:** [Artifact_001_mysql-er-diagram-improvement-design.md](Artifact_001_mysql-er-diagram-improvement-design.md)

---

## Task 1: 辞書フル再生成に変更（既存CSVを読まない）

**Files:**
- Modify: `.agent/skills/mysql-er-diagram/scripts/generate_er.py`

**Step 1:** `generate_files` 内で、既存 `_dictionary.csv` を読み込む処理を削除する。

- 削除: `existing_dict` の定義と、`if os.path.exists(csv_path):` ブロックで CSV を読んで `existing_dict` に詰める処理（おおよそ 241–250 行付近）。
- 削除: マージ用の `if key in existing_dict: ... else: ...` 分岐。常に「新規エントリ」として、`db_columns` と `potential_masters` から `new_row` を組み立てるループのみ残す。
- 結果: 毎回 DB 取得結果のみから辞書行を組み立て、CSV を全件上書きする。

**Step 2:** 動作確認

```bash
python3 .agent/skills/mysql-er-diagram/scripts/generate_er.py --db <テスト用DB名> --out /tmp/er_test
```

- 既存の `_dictionary.csv` があっても内容は無視され、その回の DB 内容で上書きされることを確認する。

**Step 3:** コミット

```bash
git add .agent/skills/mysql-er-diagram/scripts/generate_er.py
git commit -m "refactor(er): dictionary full regen, no merge with existing CSV"
```

---

## Task 2: Draw.io の色・スタイルを定数化して固定

**Files:**
- Modify: `.agent/skills/mysql-er-diagram/scripts/generate_er.py`

**Step 1:** ファイル先頭（定数・import の直後）に Draw.io 用の定数を追加する。

```python
# Draw.io スタイル（環境差で崩れないよう明示）
_DRAWIO_NODE_FILL = "#f5f5f5"
_DRAWIO_NODE_STROKE = "#666666"
_DRAWIO_NODE_FONT = "#333333"
_DRAWIO_EDGE_STROKE = "#999999"
_DRAWIO_EDGE_STROKE_WIDTH = "1"
```

**Step 2:** テーブルノードの `style` に `fontColor` を含め、上記定数を使う。

- 該当箇所: `node.set('style', "rounded=1;whiteSpace=wrap;html=1;..."` の部分。
- 例: `fillColor=%s;strokeColor=%s;fontColor=%s` を format で定数に差し替える。

**Step 3:** エッジの `style` に `strokeColor` と `strokeWidth` を追加し、定数を使う。

- 該当箇所: `edge.set('style', "edgeStyle=orthogonalEdgeStyle;..."` の部分。
- 例: `strokeColor=%s;strokeWidth=%s` を追加する。

**Step 4:** 動作確認

- 同じ `--db` / `--out` で再実行し、生成された XML を開いてノード・エッジの色が指定どおりであることを確認する。

**Step 5:** コミット

```bash
git add .agent/skills/mysql-er-diagram/scripts/generate_er.py
git commit -m "feat(er): Draw.io style constants for consistent colors"
```

---

## Task 3: .cursor に scripts と generate_er.py を配置

**Files:**
- Create: `.cursor/skills/mysql-er-diagram/scripts/generate_er.py`（.agent 側の現時点の内容をそのままコピー）

**Step 1:** ディレクトリを作成し、.agent 側のスクリプトをコピーする。

```bash
mkdir -p .cursor/skills/mysql-er-diagram/scripts
cp .agent/skills/mysql-er-diagram/scripts/generate_er.py .cursor/skills/mysql-er-diagram/scripts/
```

**Step 2:** コミット

```bash
git add .cursor/skills/mysql-er-diagram/scripts/generate_er.py
git commit -m "chore(er): add generate_er.py under .cursor for dual-directory layout"
```

---

## Task 4: SKILL.md を両ディレクトリで統一（パスのみ差し替え）

**Files:**
- Modify: `.agent/skills/mysql-er-diagram/SKILL.md`
- Modify: `.cursor/skills/mysql-er-diagram/SKILL.md`

**Step 1:** 共通の SKILL.md 本文を決める。

- 概要: BASE TABLE のみ対象、辞書は都度フル再生成、Draw.io XML と PlantUML .md の両方を常に出力、Draw.io はスタイル固定。
- 手順: 「次のコマンドを実行する」とし、**プレースホルダ**を用意する。
  - `.agent` 用: `python3 .agent/skills/mysql-er-diagram/scripts/generate_er.py --db <DB名>`
  - `.cursor` 用: `python3 .cursor/skills/mysql-er-diagram/scripts/generate_er.py --db <DB名>`
- オプション: `--out`, `--env` を記載。出力ファイル名形式 `[DB名]_dictionary.csv`, `[DB名]_er_MMDD_HHMM.xml`, `[DB名]_er_MMDD_HHMM.md` を明記。

**Step 2:** `.agent/skills/mysql-er-diagram/SKILL.md` を上記の .agent 用パスで更新する。

**Step 3:** `.cursor/skills/mysql-er-diagram/SKILL.md` を上記の .cursor 用パスで更新する（本文は .agent と同一で、実行コマンドのパスのみ .cursor 向けにする）。

**Step 4:** コミット

```bash
git add .agent/skills/mysql-er-diagram/SKILL.md .cursor/skills/mysql-er-diagram/SKILL.md
git commit -m "docs(er): unify SKILL.md for .cursor and .agent, script path per dir"
```

---

## Task 5: 今後の同期ルールを README に追記（任意）

**Files:**
- Modify: `readme.md` または `.agent/skills/mysql-er-diagram/` 配下の README があればそこに追記

**Step 1:** 「mysql-er-diagram のスクリプトは .cursor と .agent の両方に同じ内容で置く。改修時は両方の `scripts/generate_er.py` を同内容に更新すること」といった一文を追加する。

**Step 2:** コミット（変更したファイルのみ）

```bash
git add readme.md
git commit -m "docs: note dual-directory sync rule for mysql-er-diagram script"
```

---

## 実行オプション

プランは `docs/plans/2026-03-20-mysql-er-diagram-improvement.md` に保存済みです。

**実行方法は次のいずれかです。**

1. **Subagent-Driven（このセッション）** — タスクごとにサブエージェントを起動し、タスク間でレビューしながら進める。
2. **別セッションで一括** — 新しいセッションで `superpowers:executing-plans` を使い、ワークツリーでチェックポイントを挟みながら一括実行する。

どちらで進めますか？
