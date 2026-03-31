"""CP932 CSV を MySQL 8.0 に投入するためのパッケージ。

目的:
  - ステップ 1: CSV からサンプル SQL とレコード数・重複数レポートを生成する。
  - ステップ 3: 完成版 SQL を指定 DB で実行し、オプションで件数比較する。

使い方（プロジェクトルートで実行）:
  python3 -m flat_file_mysql.cli step1 file1.csv file2.csv -o ./skill_out/step1_sample_sql
  python3 -m flat_file_mysql.cli step3 complete.sql -d mydb --table mytbl --expected-count 100
  python3 -m flat_file_mysql.cli pipeline file.csv -o ./skill_out/step1_sample_sql
"""

__version__ = "0.1.0"
