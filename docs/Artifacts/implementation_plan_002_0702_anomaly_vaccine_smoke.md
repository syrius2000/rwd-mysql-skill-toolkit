# VACCINE DB 異常検知スモークテスト計画

created: 2026-07-02 00:00 (JST)
author: AI Agent (GPT-5)
status: draft

> 実行条件: ユーザーが「実行して」と明示するまで、本計画の DB 接続、SQL 実行、CSV 抽出、異常検知実行、commit / push は行わない。

## 目的

`.agent/skills/anomaly-detection/` を本リポジトリの管理対象 Skill として扱う前に、本 PC の MySQL `VACCINE` DB を使って、実データ由来の異常検知が最低限動くことを確認する。

検証は次の 2 段階で行う。

1. **1テーブルのスモークテスト**: 単一テーブルから EDC/RWD 風の入力 CSV を作り、Skill の CLI が実行できることを確認する。
2. **複数テーブル整合性テスト**: 患者/接種/観察/属性など複数テーブルを結合し、重複、欠損、日付矛盾、施設差、外れ値候補を検出できることを確認する。

## 前提

- 対象 DB: `VACCINE`
- 接続先: 本 PC の MySQL。既定候補は `-h 127.0.0.1 -P 3306`。`~/.my.cnf`、既存 SQLTools 設定、またはユーザー指定の安全な方法で認証する。
- パスワードや API キーは計画書、SQL、ログ、成果物に保存しない。
- PHI/PII は抽出しない。患者 ID は surrogate key または hash 化した `subject_id` として扱う。
- 異常検知結果は「異常確定」ではなくレビュー優先順位付けとして扱う。
- Python 依存関係は Skill 配下の `.venv` に閉じ込め、システム Python へ直接インストールしない。

## 成果物

| 種別 | 保存先 | 内容 |
|---|---|---|
| 例題プロンプト 1 | `examples/prompt/20_anomaly-vaccine-single-table-smoke.md` | 1テーブルスモークテスト用プロンプト |
| 例題プロンプト 2 | `examples/prompt/21_anomaly-vaccine-multi-table-consistency.md` | 複数テーブル整合性テスト用プロンプト |
| 抽出 SQL | `sql/drafts/anomaly_vaccine_single_table/` | 1テーブル抽出 SQL、検証 SQL、ノート |
| 抽出 SQL | `sql/drafts/anomaly_vaccine_multi_table/` | 複数テーブル結合 SQL、検証 SQL、ノート |
| 入力 CSV | `skill_out/anomaly_detection/vaccine_single_table/input.csv` | 1テーブルから作成した Skill 入力 |
| 入力 CSV | `skill_out/anomaly_detection/vaccine_multi_table/input.csv` | 複数テーブルから作成した Skill 入力 |
| 検知結果 | `skill_out/anomaly_detection/vaccine_single_table/anomaly_results.jsonl` | 1テーブル結果 |
| 検知結果 | `skill_out/anomaly_detection/vaccine_multi_table/anomaly_results.jsonl` | 複数テーブル結果 |
| レビュー | `skill_out/anomaly_detection/vaccine_single_table/review_note.md` | 結果の日本語レビュー |
| レビュー | `skill_out/anomaly_detection/vaccine_multi_table/review_note.md` | 結果の日本語レビュー |

## 使用する Skill とツール

- `.agent/skills/anomaly-detection/`
- `.agent/skills/mysql-create-query-support/`
- `.agent/skills/mysql-table-cardinality/`
- `mysql` CLI
- `python3`
- `pytest`

## 実施手順

### Task 1: 事前確認

- [ ] `git status --short --branch` で未コミット変更を確認する。
- [ ] `mysql --version` で MySQL CLI が使えることを確認する。
- [ ] `python3 --version` で Python 3.10 以上であることを確認する。
- [ ] `.agent/skills/anomaly-detection/` の仮想環境を作る。

```bash
cd /Users/myamaguchi/Documents/Codex/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -U pip
python3 -m pip install -e '.[dev]'
```

- [ ] `.agent/skills/anomaly-detection/` のテストを実行する。

```bash
cd /Users/myamaguchi/Documents/Codex/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection
source .venv/bin/activate
python3 -m pytest tests -q
```

期待結果: `test_pipeline.py`, `test_rules.py`, `test_schemas.py` が通る。

### Task 2: VACCINE DB の候補テーブル確認

- [ ] DB 接続を確認する。

```bash
MYSQL_ARGS="-h 127.0.0.1 -P 3306 VACCINE"
mysql $MYSQL_ARGS -N -B -e "SELECT DATABASE(), @@hostname, @@port, @@version;"
```

期待結果:

- 1列目が `VACCINE`
- `@@port` が想定する MySQL ポート
- `@@version` が意図した MySQL/MariaDB インスタンス

補足:

- `~/.my.cnf` で接続先が正しく固定されている場合のみ、`MYSQL_ARGS="VACCINE"` に短縮してよい。
- QNAP MariaDB を使う場合は、例として `MYSQL_ARGS="-h 192.168.0.110 -P 3307 VACCINE"` のように明示する。

- [ ] テーブル一覧を取得する。

```bash
mysql $MYSQL_ARGS -N -B -e "SHOW FULL TABLES WHERE Table_type = 'BASE TABLE';"
```

- [ ] 行数、日付列、数値列、ID 候補列を確認する。

```sql
SELECT
  TABLE_NAME,
  COLUMN_NAME,
  DATA_TYPE,
  ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'VACCINE'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

実行例:

```bash
mysql $MYSQL_ARGS -N -B -e "
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'VACCINE'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
"
```

選定基準:

- 1テーブルスモークテストは、行数が十分あり、ID、日付、数値列を含むテーブルを優先する。
- 複数テーブル整合性テストは、患者 ID または接種 ID で join でき、日付列とイベント/属性列を持つ組み合わせを優先する。
- PHI/PII らしい列は抽出対象から外す。

### Task 3: 1テーブルスモークテスト用プロンプト作成

- [ ] `examples/prompt/20_anomaly-vaccine-single-table-smoke.md` を作成する。

内容:

```markdown
# anomaly-detection: VACCINE 1テーブルスモークテスト

VACCINE DB の単一テーブルを使い、`.agent/skills/anomaly-detection/` の動作確認をしてください。

目的:
- 実データ由来 CSV で異常検知 CLI が動くことを確認する
- 必須欠損、重複キー、日付矛盾、数値外れ値候補をレビューキューとして出す

手順:
1. `VACCINE` DB のテーブル一覧とカラム一覧を確認する
2. 行数、ID 候補、日付列、数値列を見て、1テーブルを選ぶ
3. `sql/drafts/anomaly_vaccine_single_table/` に `main_query.sql`, `validation_query.sql`, `query_note.md` を作成する
4. 抽出結果を `skill_out/anomaly_detection/vaccine_single_table/input.csv` に保存する
5. `.agent/skills/anomaly-detection/scripts/infer.py` を実行する
6. 結果を `skill_out/anomaly_detection/vaccine_single_table/review_note.md` に日本語で要約する

入力 CSV の列名は可能な範囲で以下に合わせる:
- `record_id`
- `study_id`
- `site_id`
- `subject_id`
- `form_name`
- `visit_date`
- `recorded_at`
- `age`
- `sbp`
- `dbp`
- `lab_value`
- `is_query_open`

制約:
- PHI/PII を出力しない
- 患者 ID は surrogate key または hash 化する
- 異常確定ではなくレビュー優先順位付けとして記述する
```

### Task 4: 1テーブル抽出 SQL 作成

- [ ] `sql/drafts/anomaly_vaccine_single_table/main_query.sql` を作成する。

SQL 方針:

- `record_id`: テーブル主キー、または `ROW_NUMBER()` から作る。
- `study_id`: 固定値 `'VACCINE'`
- `site_id`: 施設/地域/実施主体列があれば使用し、なければ `'UNKNOWN_SITE'`
- `subject_id`: 患者 ID 候補を SHA2 などで hash 化する。ID がなければ `record_id` ベースの surrogate key。
- `form_name`: テーブル名を固定値として入れる。
- `visit_date`: 接種日、受診日、イベント日などの主日付。
- `recorded_at`: 登録日、更新日、作成日があれば使用し、なければ `visit_date`。
- `age`, `sbp`, `dbp`, `lab_value`: 実テーブルに存在する数値列を割り当てる。

実行例:

```bash
mysql $MYSQL_ARGS --batch --raw < sql/drafts/anomaly_vaccine_single_table/main_query.sql > skill_out/anomaly_detection/vaccine_single_table/input.tsv
```

TSV から CSV に変換する場合:

```bash
python3 - <<'PY'
import pandas as pd
df = pd.read_csv("skill_out/anomaly_detection/vaccine_single_table/input.tsv", sep="\t")
df.to_csv("skill_out/anomaly_detection/vaccine_single_table/input.csv", index=False)
PY
```

### Task 5: 1テーブル異常検知実行

- [ ] Skill の仮想環境を有効化する。

```bash
cd /Users/myamaguchi/Documents/Codex/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection
source .venv/bin/activate
python3 -m pytest tests -q
```

- [ ] 異常検知を実行する。

```bash
cd /Users/myamaguchi/Documents/Codex/rwd-mysql-skill-toolkit
.agent/skills/anomaly-detection/.venv/bin/python .agent/skills/anomaly-detection/scripts/infer.py \
  --input skill_out/anomaly_detection/vaccine_single_table/input.csv \
  --output skill_out/anomaly_detection/vaccine_single_table/anomaly_results.jsonl \
  --config .agent/skills/anomaly-detection/configs/default.yaml \
  --format jsonl
```

期待結果:

- `anomaly_results.jsonl` が生成される。
- `n_records` が入力 CSV 行数と一致する。
- `n_returned` が 1 以上になる。
- `triggered_rules` または `model_contributions` が含まれる。

### Task 6: 複数テーブル整合性テスト用プロンプト作成

- [ ] `examples/prompt/21_anomaly-vaccine-multi-table-consistency.md` を作成する。

内容:

```markdown
# anomaly-detection: VACCINE 複数テーブル整合性テスト

VACCINE DB の複数テーブルを結合し、`.agent/skills/anomaly-detection/` で整合性由来の異常候補を検出してください。

目的:
- 患者/接種/観察/属性など複数テーブルの join 後データで異常検知を行う
- 重複、欠損、日付矛盾、施設差、数値外れ値、未解決 query 相当の列をレビュー対象にする

手順:
1. `VACCINE` DB の ER 的な関係を確認する
2. join key 候補と粒度を決める
3. `sql/drafts/anomaly_vaccine_multi_table/` に `main_query.sql`, `validation_query.sql`, `query_note.md` を作成する
4. 抽出結果を `skill_out/anomaly_detection/vaccine_multi_table/input.csv` に保存する
5. `.agent/skills/anomaly-detection/scripts/infer.py` を実行する
6. 結果を `skill_out/anomaly_detection/vaccine_multi_table/review_note.md` に日本語で要約する

粒度:
- 原則は 1行 = 1患者 x 1接種または 1患者 x 1イベント
- join によって行数が増える場合は、validation query で原因を確認する

制約:
- PHI/PII を出力しない
- 患者 ID は surrogate key または hash 化する
- join 前後の `COUNT(*)` と `COUNT(DISTINCT subject_id)` を必ず比較する
- 異常確定ではなくレビュー優先順位付けとして記述する
```

### Task 7: 複数テーブル抽出 SQL 作成

- [ ] `sql/drafts/anomaly_vaccine_multi_table/main_query.sql` を作成する。

SQL 方針:

- 主要テーブルを 1 つ決める。
- 患者 ID、接種 ID、イベント ID、日付列の候補を確認する。
- join 前後で行数が増えすぎないように、必要に応じて window 関数で 1 レコードへ絞る。
- 日付矛盾を検出できるよう、`visit_date` と `recorded_at` に別由来の日付を割り当てる。
- 未解決 query 相当の列がなければ `0 AS is_query_open` とする。

検証 SQL には必ず含める:

```sql
SELECT COUNT(*) AS n_rows FROM extracted_dataset;
SELECT COUNT(DISTINCT subject_id) AS n_subjects FROM extracted_dataset;
SELECT record_id, COUNT(*) AS n FROM extracted_dataset GROUP BY record_id HAVING COUNT(*) > 1;
SELECT MIN(visit_date), MAX(visit_date), MIN(recorded_at), MAX(recorded_at) FROM extracted_dataset;
```

### Task 8: 複数テーブル異常検知実行

- [ ] 抽出 CSV を作る。
- [ ] 異常検知を実行する。

```bash
cd /Users/myamaguchi/Documents/Codex/rwd-mysql-skill-toolkit
.agent/skills/anomaly-detection/.venv/bin/python .agent/skills/anomaly-detection/scripts/infer.py \
  --input skill_out/anomaly_detection/vaccine_multi_table/input.csv \
  --output skill_out/anomaly_detection/vaccine_multi_table/anomaly_results.jsonl \
  --config .agent/skills/anomaly-detection/configs/default.yaml \
  --format jsonl
```

期待結果:

- `anomaly_results.jsonl` が生成される。
- 1テーブルテストと比べ、join 由来の欠損、重複、日付矛盾、外れ値候補が評価できる。
- join の増幅や欠損が見つかった場合は、異常候補とは別にデータセット作成上の注意として記録する。

### Task 9: レビューとコミット準備

- [ ] `review_note.md` に以下を記録する。

記録項目:

- 実行日時 JST
- 対象 DB と対象テーブル
- 入力行数
- 上位 10 件の異常候補
- rule evidence と model evidence の分離
- 誤検知の可能性
- 次に見るべきテーブル/カラム

- [ ] `.gitignore` の対象を確認し、実データ抽出 CSV や結果ファイルを不用意に commit しない。
- [ ] commit 対象は原則として、Skill 本体、例題プロンプト、SQL テンプレート/ノート、テスト計画に限定する。
- [ ] push 前に `git status --short` を確認する。

## 完了条件

- 1テーブルスモークテストのプロンプト、SQL、検知結果、レビューが揃っている。
- 複数テーブル整合性テストのプロンプト、SQL、検知結果、レビューが揃っている。
- `.agent/skills/anomaly-detection/` の Python テストが通っている。
- 実データや PHI/PII を commit 対象に含めていない。
- push 前に、ユーザーが結果レビューと commit 範囲を確認済みである。
