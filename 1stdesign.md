## Context

CP932 の CSV フラットファイルを MySQL 8.0 へ投入する前に、DDL 作成・重複除去・エンコーディング検証・件数比較を手作業で行う現状を改善する。プロジェクトの技術スタックは Python / SQL。MySQL 8.4（Mac）、MariaDB（QNAP）などの DB 環境を想定。

## Goals / Non-Goals

**Goals:**
- 過去プロジェクトのコードを参考にする。参考とするコードは、AnotherPJのコードを参考にする
  - make_sample_sql_files.pyを参考にする。
  - read_sample_bytes.pyを参考にする。
  - detect_encoding.pyを参考にする。
  - read_sample_bytes.pyを参考にする。
  - read_sample_bytes.pyを参考にする。
  - AnotherPJ/sample-template/CH_t05_covid_vaccine.txtImport.sqlのようなサンプルSQLファイルを作成する。
    - AnotherPJ/sample-template/SQLDistinct.prompt.mdを参考にする。
    - AnotherPJ/sample-template/SQLInsert.prompt.mdを参考にする。
- CP932 CSV から MySQL 8.0 互換 DDL を自動生成するSkill.mdを作成する。そのSkillを利用して、CSVをMySQLに投入する。
- 重複レコードの検出・削除とレポート出力
- エンコーディング検証（CP932 前提）
- フラットファイル件数・重複件数・DB 投入件数の比較バリデーション
- validation.mdを作成する。
  - 各CSVファイルのレコード数をカウントする。その中に重複がある場合を検出し、レポートする。
  - 重複がある場合は、重複しているレコードを削除し、ユニークなレコードを作成する。
  - ユニークなレコードを作成したら、MySQLに投入する。
  - 投入したら、MySQLのレコード数をカウントする。
  - カウントしたレコード数と、投入したレコード数を比較し、一致しない場合は、エラーを報告する。
  - 一致する場合は、成功を報告する。

**Non-Goals:**
- UTF-8 以外の出力形式への変換
- リアルタイム同期やストリーミング
- Web UI の提供

## Decisions

| 決定 | 理由 | 代替案 |
|------|------|--------|
| Python CLI | 既存スタックに合わせ、CSV 処理・DB 接続ライブラリが豊富 | Node.js / R |
| pandas + chardet | 型推論と CP932 検出の組み合わせ | csv + codecs のみ（手間増） |
| DDL は LOAD DATA 対応想定 | INSERT ベースでは大量なので不可と考える | LOAD DATA LOCAL（セキュリティ考慮） |
| バリデーションはレポート出力 | ログ・ファイルで追跡可能にする | DB 内ログテーブルのみ |

## Risks / Trade-offs

| リスク | 対策 |
|--------|------|
| 大容量 CSV でメモリ不足 | チャンク読み込み・バッチ INSERT オプション |
| CP932 外の文字混入 | ほとんどのケースでは阪大はCP932でWindows外字が混入していると考える。検証フェーズでエラー報告、スキップ/修正オプション |
| 重複判定カラムの指定ミス | スキーマ定義または CLI 引数で明示、ドキュメント化 |
