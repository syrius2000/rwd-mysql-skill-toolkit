# 対象スキル
mysql-create-query-support

## 標準プロンプト（コピペ用）
> example/mf.db のテーブルを使用し、カテゴリごとの支出合計額（Spending）を算出するSQLを生成してください。本SQLと検証SQLを example/sql/drafts/mf_category_spending/ 配下に作成してください。SQLite互換となるように配慮してください。

## 入出力（example 固定）

- 入力: `example/mf.db` および ER図（`example/skill_out/mf_dictionary.csv` 等）
- 出力:
  - `example/sql/drafts/mf_category_spending/main_query.sql` (カテゴリ別支出集計SQL)
  - `example/sql/drafts/mf_category_spending/validation_query.sql` (総件数・総額チェック用検証SQL)
  - `example/sql/drafts/mf_category_spending/query_note.md` (分析設計書、仕様メモ)

## 完了チェックリスト

- [ ] `main_query.sql` が正しく作成されていること
- [ ] `validation_query.sql` が正しく作成されていること
- [ ] `query_note.md` に分析意図や考慮点（粒度、JOIN時の重複排除など）がまとめられていること
