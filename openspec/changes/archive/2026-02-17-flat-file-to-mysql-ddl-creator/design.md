## Context

CP932 の CSV フラットファイルを MySQL 8.0 へ投入する前に、DDL 作成・重複除去・エンコーディング検証・件数比較を手作業で行う現状を改善する。プロジェクトの技術スタックは Python / SQL。MySQL 8.4（Mac）、MariaDB（QNAP）などの DB 環境を想定。

## フロー概要（3 ステップ）

1. **ステップ 1**: CSV を読み、エンコードを確認し、数行の DDL 用サンプル SQL を作成。対象 CSV のレコード数・重複数をレポート（複数 CSV 対応）。
2. **ステップ 2**: ステップ 1 の出力と保存されたプロンプトに従い、完成版インポート SQL を作成。対象 DB 名は指定を求める。
3. **ステップ 3**: 完成した SQL を指定した対象 DB へ実行（インポート）する。

## 実行主体・DB 名・成果物

| 項目 | 内容 |
|------|------|
| **ステップ 2 の実行主体** | エージェント。ステップ 1 の出力と保存プロンプトを渡し、完成版 SQL を生成する。 |
| **DB 名** | Skill を実行するたびに、DB 名が未指定ならエージェントがユーザーに問い合わせる。未指定のままの場合は「DB名を明示してから実行してください」と表示し、**ステップ 2 の前でストップ**する（完成版 SQL に `USE dbname` や `dbname.tbl` が含まれるため）。検知は **Skill C（エージェントの手順）** で行う。Step 2 に進む前にエージェントが DB 名の有無を確認する。CLI 側での DB 名必須チェックは Step 3 実行時に行う（オプション）。 |
| **数行の SQL の意図** | 複数 CSV がある場合、CSV ごとに 1 本のサンプル／完成版 SQL を発生させる。 |
| **Skill の置き場所** | 当リポジトリ（本 change の成果物として配置する）。 |

## Skill と CLI の境界

実行主体はエージェント。Step 1 と Step 3 ではエージェントが Python CLI を呼び出す。Step 2 では CLI は使わない。

| ステップ | 実行主体 | CLI 利用 |
|----------|----------|----------|
| **Step 1** | エージェントが **Skill B** に従う | **Python CLI**（ステップ 1 用）を呼び出す。CLI がサンプル SQL 生成とレポート出力を行う。 |
| **Step 2** | エージェントがステップ 1 の出力とステップ 2 用プロンプト（＋DB 名）で完成版 SQL を生成 | 呼ばない。 |
| **Step 3** | エージェントが **Skill C** に従う | **Python CLI**（ステップ 3 用：SQL 実行・件数比較）を呼び出す。 |

```
Step1 サンプルSQL+レポート --> Step2 完成版SQL(DB名指定) --> Step3 DBへ投入
        ^                              |                            ^
        |                              |                            |
   エージェント + CLI              エージェントのみ              エージェント + CLI
```

## 参照コード・ドキュメント（AnotherPJ）

| 種別 | パス | 用途 |
|------|------|------|
| Python | AnotherPJ/make_sample_sql_files.py | サンプル SQL 生成・バイト読み・エンコード検出の参考（`_read_sample_bytes`, `detect_encoding`, `TRY_ENCODINGS` を参照） |
| .md | AnotherPJ/readme.md | インポートの注意点（エンコーディング、重複、LOAD DATA 等） |
| .md | AnotherPJ/SQLImportAndDedupe.prompt.md | CSV→一時テーブル→LOAD DATA→重複削除→本番テーブルの一連フロー（保存プロンプト） |
| .md | AnotherPJ/SQLDistinct.prompt.md | テーブル重複削除 SQL 生成 |
| SQL | AnotherPJ/sample-template/CH_t05_covid_vaccine.txtImport.sql 等 | サンプル SQL 形式の参考 |

上記 AnotherPJ のプロンプト（.md）は**参照**であり、DB 名が固定の記述を含む。本 change ではステップ 2 用に **DB 名を指定可能なプロンプトを新規に作成**する。DB 名は変数（例: `{{database_name}}`）化するか、エージェントがユーザーから受け取った値をプロンプト実行時に渡す形で利用する。

## Goals / Non-Goals

**Goals:**

- 上記参照を土台に、CP932 CSV から MySQL 8.0 互換 DDL を自動生成する **Skill.md** を 2 分割で作成する
  - **Skill B**: DDL 生成（CSV→数行サンプル SQL＋レポート。CREATE TABLE / LOAD DATA 用）
  - **Skill C**: 投入とバリデーション（完成版 SQL 作成支援・指定 DB への実行・件数比較）
  - オーバービュー: B→C の一連の流れ（ステップ 1→2→3）を説明する README または親 Skill.md
- その Skill を利用して、CSV を MySQL に投入する流れを確立する
- 重複レコードの検出・削除とレポート出力（重複判定: 未指定時は全カラム一致、指定時はキーカラム）。複数 CSV 対応
- エンコーディング検証（CP932 前提）。パイプライン内で標準ライブラリ（codecs 等）により実施し、専用 .py は持たない
- フラットファイル件数・重複件数・DB 投入件数の比較バリデーション
- 当 change 配下に **validation.md** を置き、バリデーション手順・フローを記述する
- ステップ 2 で対象 **DB 名を指定**する

**Non-Goals:**

- UTF-8 以外の出力形式への変換
- リアルタイム同期やストリーミング
- Web UI の提供

## 投入方式（LOAD DATA と INSERT）

| 方式 | 用途 | 備考 |
|------|------|------|
| LOAD DATA | 大容量。DDL は LOAD DATA 対応を想定 | セキュリティのため LOAD DATA LOCAL を考慮 |
| INSERT / バッチ | 中〜小容量、初期実装や検証 | チャンク読み込み・バッチ INSERT オプションで対応 |

## Decisions

| 決定 | 理由 | 代替案 |
|------|------|--------|
| Python CLI | 既存スタックに合わせ、CSV 処理・DB 接続ライブラリが豊富 | Node.js / R |
| エンコーディング・型推論 | パイプライン内で標準ライブラリ（codecs、TRY_ENCODINGS 方式）を主とする。型推論・一括処理で pandas を使う場合は pandas も利用。chardet はオプション。専用 .py は持たない | chardet 必須 / csv のみ |
| DDL は LOAD DATA 対応想定 | INSERT ベースでは大量なので不可と考える | LOAD DATA LOCAL（セキュリティ考慮） |
| バリデーションはレポート出力 | ログ・ファイルで追跡可能にする | DB 内ログテーブルのみ |
| validation.md の配置 | 当 change 配下 | docs 直下など |

## Risks / Trade-offs

| リスク | 対策 |
|--------|------|
| 大容量 CSV でメモリ不足 | チャンク読み込み・バッチ INSERT オプション |
| CP932 外の文字混入 | 検証フェーズでエラー報告、スキップ/修正オプション |
| 重複判定カラムの指定ミス | スキーマ定義または CLI 引数で明示、ドキュメント化 |
