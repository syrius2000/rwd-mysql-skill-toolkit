# flat-file-to-mysql-ddl-creator 作り直し計画

created: 2025-02-16 12:30 (JST)  
author: AI Agent (LLM Model)

---

## 1. 目的

1stdesign.md を土台に、既存 change `flat-file-to-mysql-ddl-creator` の proposal / design / specs / tasks を一貫して作り直す。

---

## 2. 反映する 1stdesign の要点（整理版）

- **参照コード**: AnotherPJ の `make_sample_sql_files.py`、`read_sample_bytes.py`、`detect_encoding.py`。サンプル SQL は `CH_t05_covid_vaccine.txtImport.sql` のような形式。`SQLDistinct.prompt.md` / `SQLInsert.prompt.md` を参照。
- **成果物**: (1) CP932 CSV → MySQL 8.0 互換 DDL を自動生成する **Skill.md**、(2) その Skill を使って CSV を MySQL に投入する流れ、(3) **validation.md**（バリデーション手順・フローのドキュメント）。
- **validation フロー**: レコード数カウント → 重複検出・レポート → 重複削除 → ユニーク CSV 作成 → MySQL 投入 → 投入後件数カウント → 件数比較 → 一致時は成功報告、不一致時はエラー報告。
- **重複**: 1stdesign の「read_sample_bytes.py」3回は 1 つに整理。

---

## 3. 改善アイデア（提案）

| # | 内容 | 理由 |
|---|------|------|
| 1 | **Artifact の順序を「参照→Skill→validation」に明示** | 1stdesign の「参考コード → Skill → validation.md」の依存関係を design/tasks に落とす。 |
| 2 | **spec を 1 つ追加: `validation-doc`** | 「validation.md が存在し、フロー（カウント→重複検出→削除→投入→件数比較→報告）が記述されている」を要件化。 |
| 3 | **tasks に「参照コード分析」「Skill.md 作成」「validation.md 作成」を明示** | 現行 tasks は CLI/検証/DDL/投入に偏っている。1stdesign の「参考にする」「Skill を作る」「validation を書く」をタスクとして並べる。 |
| 4 | **LOAD DATA と INSERT の役割を design で分離** | DDL は LOAD DATA 対応、一方で「サンプル SQL（INSERT 形式）」も参照する。初期は INSERT/バッチで投入し、大容量は LOAD DATA オプションとする等、段階を design に書く。 |
| 5 | **重複判定のデフォルト** | 指定がなければ「全カラム一致」、指定があれば「キーカラム」とし、spec と design の両方に同じ定義を書く。 |

---

## 4. 回答反映（確定事項）

| 項目 | 内容 |
|------|------|
| **detect_encoding.py** | 失っているため、標準ライブラリ中心の Python で新規作成する。 |
| **参照 .md** | AnotherPJ を再確認。存在する .md: `readme.md`, `SQLImportAndDedupe.prompt.md`, `SQLDistinct.prompt.md`。`SQLInsert.prompt.md` はなし → インポート＋重複削除の一連フローは `SQLImportAndDedupe.prompt.md` を参照する。 |
| **validation.md の置き場所** | change 配下（`openspec/changes/flat-file-to-mysql-ddl-creator/`）がよい。 |
| **specs** | 既存の `specs/*/spec.md` の内容は破棄する。これから検討して変える前提。 |

---

## 4b. Skill.md の 1本 vs 3分割 — アドバイス

**希望**: 一連の流れを記載したい。

**3分割を推す理由**

| 観点 | 1本 | 3分割 |
|------|-----|--------|
| メンテ | 長くなると追いづらい | 責務ごとに編集しやすい |
| 再利用 | 「DDLだけ」「検証だけ」で使いたいときに探しづらい | サブSkillを単体で呼べる |
| 一連の流れ | そのまま1ファイルで読める | 親でオーバービューを書けば同じ体験にできる |

**推奨**: **3分割 + オーバービュー**  
- **Skill A**: CP932 検証・エンコーディング（detect + 検証手順）  
- **Skill B**: DDL 生成（CSV→CREATE TABLE / LOAD DATA 用）  
- **Skill C**: 投入とバリデーション（重複検出→削除→投入→件数比較）  
- **オーバービュー**: 上記 A→B→C の順で「一連の流れ」を説明する README または親 Skill.md を 1 本置く。

これで「流れは1か所」「細部はサブSkill」の両立ができる。

---

## 4c. 疑問点（未確定なら確認）

| # | 疑問 | 選択肢の例 |
|---|------|------------|
| Q5 | 作り直しの**範囲**は？ | (A) proposal / design / tasks を 1stdesign ベースで更新（specs は後で検討） (B) 実装も含めてゼロから揃える |

---

## 5. 作り直し後の artifact 構成案

```
openspec/changes/flat-file-to-mysql-ddl-creator/
├── proposal.md
├── design.md      … 1stdesign ベース + 参照一覧（AnotherPJ .md / make_sample_sql_files.py / detect_encoding.py 新規）、validation フロー、validation.md は当 change 配下
├── validation.md  … 当 change 配下に配置（フロー: カウント→重複検出→削除→投入→件数比較→報告）
├── specs/         … 既存内容は破棄済み。これから検討して追加する。
└── tasks.md       … 参照分析 → detect_encoding.py 作成 → Skill（3分割案）→ validation.md → CLI/検証/DDL/投入/統合
```

---

## 6. 次のステップ

- **Q5**（範囲: artifact のみ / 実装も含む）が決まれば、proposal / design / tasks の文案を作成する。
- **承認（Approval）** 後に該当ファイルを更新する。
