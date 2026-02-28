# AnotherPJ 参照分析

本 change で参照する AnotherPJ のコード・ドキュメントの要約。

## make_sample_sql_files.py

- **役割**: 指定ディレクトリ直下の CSV/TXT を走査し、各ファイルの先頭4行をコメントに含む `*元ファイル名+Import.sql` の SQL 雛形を生成する。
- **エンコーディング**: 独立した `read_sample_bytes.py` は存在しない。`_read_sample_bytes(path, max_bytes, sample_lines)` および `detect_encoding(path, encodings=TRY_ENCODINGS, ...)` が同一ファイル内に実装。`TRY_ENCODINGS = ["utf-8", "utf-8-sig", "cp932", "shift_jis", "euc_jp", "iso2022_jp"]` を順に試行。
- **出力形式**: メタ情報コメント（元ファイル、推定エンコーディング、生成日時）、先頭4行プレビュー、LOAD DATA INFILE 雛形コメント。

## readme.md

- **役割**: RDBMS へのインポート Tips。カラム長・NULL・Encoding・セパレータ・重複・外字・構造不正・複数ファイルの注意点。LOAD DATA の事例、nkf によるエンコーディング調査、重複対応（RDBMS で削除 or CSV 段階で削除）を記載。

## SQLImportAndDedupe.prompt.md

- **役割**: CSV サンプルを基に、一時テーブル→LOAD DATA→DISTINCT で本番テーブル→重複確認クエリ→クリーンアップの一連 SQL を生成するプロンプト。使い方: ファイルに 3〜4 行の CSV サンプルを貼り付け、選択してプロンプト実行。
- **DB 名**: 要件で `VACCINE` 固定。本 change では DB 名を指定可能なプロンプトを新規作成する。

## SQLDistinct.prompt.md

- **役割**: テーブルの重複行を削除する SQL を生成。SELECT DISTINCT で新テーブル作成、元テーブル削除、重複行確認用クエリ。DB 名は VACCINE 固定。

## サンプル SQL（CH_t01 / CH_t05 等）

- **形式**: 元ファイル名・推定エンコーディング・生成日時・先頭4行プレビューをコメントで記載し、その後に LOAD DATA 雛形（CHARACTER SET cp932、FIELDS TERMINATED BY 等）をコメントで記載。本 change のステップ 1 の出力はこの形式を参考にする。
