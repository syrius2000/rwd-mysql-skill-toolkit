# 対象スキル
mysql-table-cardinality

## 標準プロンプト（コピペ用）
> example/mf.db の全テーブルを対象に、カラムごとの総行数および濃度数（cardinality）を調査してください。出力は example/skill_out/mysql_table_cardinality/ 配下に保存してください。なお、実環境では MySQL コマンドが使用できないため、事前作成された静的成果物（example/skill_out/mysql_table_cardinality/）を参照して結果を説明してください。

## 入出力（example 固定）

- 入力: `example/mf.db` (MySQL想定、研修時は静的成果物参照)
- 出力:
  - `example/skill_out/mysql_table_cardinality/cardinality_report.csv` (濃度数一覧)
  - `example/skill_out/mysql_table_cardinality/cardinality_report.json` (JSONメタデータ)

## 完了チェックリスト

- [ ] `example/skill_out/mysql_table_cardinality/` 配下のCSV/JSONが存在し、内容が正しく解釈されていること
- [ ] カラムのユニーク度（一意キーの判定など）についてエージェントから説明があること
