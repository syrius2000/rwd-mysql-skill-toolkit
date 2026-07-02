# 対象スキル
mysql-entity-matrix

## 標準プロンプト（コピペ用）
> 合成 RWD 想定 DBにおける PatientID カラムの存在マトリクス（Entity Presence Matrix）を生成・説明してください。出力は example/skill_out/mysql-entity-matrix/ 配下に保存してください。なお、実環境では MySQL コマンドが使用できないため、事前作成された静的成果物（example/skill_out/mysql-entity-matrix/）を参照して説明してください。

## 入出力（example 固定）

- 入力: 合成 RWD スキーマ (MySQL想定、研修時は静的成果物参照)
- 出力:
  - `example/skill_out/mysql-entity-matrix/entity_matrix_report.md` (マトリクスレポート)

## 完了チェックリスト

- [ ] `example/skill_out/mysql-entity-matrix/entity_matrix_report.md` が存在し、各テーブルにおける PatientID の有無が [1, 0] で整理されていること
- [ ] どのテーブルが PatientID を保持し、分析時にどのようにJOIN可能であるかの解説があること
