created: 2026-02-16 15:00
author: AI Agent (LLM Model)

# flat-file-to-mysql-ddl-creator 探索レポート

セカンドオピニオン検討用。`/opsx-explore flat-file-to-mysql-ddl-creator` による探索結果。

---

## 現状サマリ

| 項目 | 状態 |
|------|------|
| **OpenSpec** | in-progress、タスク 0/15 完了 |
| **AnotherPJ** | 存在。`make_sample_sql_files.py`、プロンプト類、サンプル SQL あり |
| **定義** | proposal / design / tasks / validation が一通り揃っている |

---

## アーキテクチャの整理

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        3 ステップ パイプライン                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐          │
│  │  Step 1      │      │  Step 2      │      │  Step 3      │          │
│  │  サンプル SQL │ ───▶ │  完成版 SQL   │ ───▶ │  DB へ投入   │          │
│  │  + レポート   │      │  (DB名指定)   │      │              │          │
│  └──────────────┘      └──────────────┘      └──────────────┘          │
│         │                      │                      │                 │
│         ▼                      ▼                      ▼                 │
│  Python CLI              エージェント              Python CLI            │
│  (パイプライン内)         (プロンプト使用)          (実行)               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

- Step 1, 3: **Python CLI** が実行主体
- Step 2: **AI エージェント** がプロンプト＋サンプル SQL を元に完成版 SQL を生成

---

## 気になった点（議論候補）

### 1. design.md と AnotherPJ のギャップ

design.md は `AnotherPJ/read_sample_bytes.py` を参照としているが、AnotherPJ には**独立ファイルが存在しない**。`make_sample_sql_files.py` 内の `_read_sample_bytes` 関数として実装されている。

→ design.md の参照一覧を更新するか、「存在する場合」の扱いを明確にする価値あり。

### 2. 技術選定の揺れ（エンコーディング）

- **design**: pandas + chardet
- **AnotherPJ**: 標準ライブラリ中心、`TRY_ENCODINGS` の順に試す方式（chardet 非使用）

どちらを正式採用するか、トレードオフ（精度 vs 依存・複雑さ）を検討の余地あり。

### 3. Skill と CLI の境界

tasks.md では Skill B/C と Python CLI が並ぶ。

- Skill B/C: エージェントの「やることリスト」
- CLI: Step 1 / 3 の実際の処理

「Skill B を実行 = エージェントが CLI を呼ぶ」のか、別のワークフローかを明確にすると設計が安定する。

### 4. DB 名未指定時のストップ位置

design では「DB 名未指定なら Step 2 の前でストップ」とあるが、**誰が**それを検知するかは明文化されていない。Skill C 側の指示で担保するのか、CLI にチェックを入れるのか、両方か。

---

## 次の一手候補

| 方向 | 内容 |
|------|------|
| **A. ギャップ解消** | design.md の AnotherPJ 参照を実態に合わせて更新 |
| **B. 技術方針の確定** | エンコーディング検出を chardet / 標準ライブラリのどちらで統一するか決定 |
| **C. ワークフロー整理** | Skill と CLI の境界を図で固定し、tasks.md に反映 |
| **D. 実装着手** | タスク 1.1（AnotherPJ 分析）から着手 |

---

## 参照

- `openspec/changes/flat-file-to-mysql-ddl-creator/` 配下の proposal, design, tasks, validation
- `AnotherPJ/` の make_sample_sql_files.py, SQLImportAndDedupe.prompt.md 等
- `docs/Artifacts/walkthrough0217_0020.md`（既存のリポジトリ分析）
