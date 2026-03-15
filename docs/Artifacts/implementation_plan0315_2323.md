created: 2026-03-15 23:23 (JST)
author: AI Agent (Gemini 2.0 Pro)

# SQL Generator Skill (mysql-entity-matrix) Security Audit Report

`security-vulnerability-check` スキルの基準、および `bandit` 静的解析結果に基づく `scripts/generate_matrix_sql.py` のセキュリティ監査レポートと修正提案（実装計画）です。ユーザーは安全性を確認のうえ、このまま Git Push するか、あるいは追加のコード堅牢化を行うか（Approve）をご判断ください。

## 1. 監査結果概要 (Executive Summary)

ローカル環境や開発者が直接実行する分には**致命的なリスクは低く、安全に動作します**。
しかし、外部ユーザーからの入力をそのまま引数（API等）として受け取るような運用へと拡張した場合、いくつかの潜在的脆弱性（主にインジェクション系）が指摘されます。

### 監査パス済み (Pass)
- 🟢 **OSコマンドインジェクション**: `subprocess.run` 呼び出し時、`shell=True` を使わず、全てのコマンドと引数を `list[str]` として直接渡しているため、引数からシェルコマンドへのエスケープ（`&& rm -rf /` など）は発生しません。安全かつセオリー通りの実装です。
- 🟢 **パスワードのハードコード**: ソースコードにDBパスワードはハードコードされておらず、引数（または `~/.my.cnf`）から受け取っています。

## 2. 潜在的リスクと警告項目 (Warnings & Potential Risks)

静的解析ツール(Bandit)やコードレビューで検知された、対処を検討すべき項目は以下の通りです。

### ⚠️ [Risk 1] SQLインジェクション (String Formatting)
- **該当箇所**:
  - `get_tables_with_column()` におけるクエリ生成 (`f"SELECT ... TABLE_SCHEMA = '{db_name}' AND COLUMN_NAME = '{column_name}';"`)
  - `generate_matrix_sql()` におけるCTEとSELECT文の生成。
- **詳細**: `mysql` コマンドラインツール（CLI）経由で実行するため、通常のDB-APIのようなバインド変数（Prepared Statement）が使えません。そのため、`--database` や `--id_column` に悪意のある文字列（例: `FUGA'; DROP TABLE ...; --`）が渡された場合、SQLとしてそのままパースされる危険性があります。
- **対処の要否**: スキルはユーザー（開発者自身）がローカル・NAS環境でCLIから叩く前提のため実害はほぼありません。ただ、不特定多数の入力を受け付ける仕組みへ乗せる場合は対策（サニタイズ処理）が必須です。

### ⚠️ [Risk 2] 出力ファイル名におけるパストラバーサル (Path Traversal)
- **該当箇所**: `f"matrix_query_{args.database}_{timestamp}.sql"` などのファイル名生成。
- **詳細**: `--database` 引数に `../../../` などの文字が含まれていた場合、意図しない階層へファイルが書き込まれる恐れがあります。CLI実行においては通常起こり得ませんが、脆弱性の一種です。

### ⚠️ [Risk 3] 実行可能パスの絶対化
- **該当箇所**: `cmd = ["mysql", ...]`
- **詳細**: `mysql` を相対実行しているため、環境変数 `$PATH` が汚染されている場合に別の悪意あるバイナリが呼ばれる可能性があります（BanditのB607警告）。

## 3. User Review Required (判断・承認タスク)

> [!IMPORTANT]
> 上記の監査結果を踏まえ、現在のスクリプト (`generate_matrix_sql.py`) に対してどのように対応するかをご指示ください。

- **[選択肢 1] 現行のままPushする**: 開発用途・限定環境での利用と割り切り、修正は行わず `git push` に進む。（推奨）
- **[選択肢 2] 追加の堅牢化修正を行う（このプランをApprove）**: 以下の修正を実施してから Push する。
  - **修正案A**: `db_name` および `id_column` の文字列から「英数字・アンダースコア」以外の怪しい文字（クォートやセミコロンなど）を除外、もしくはエラーとする入力検証（サニタイズ）を追加する。
  - **修正案B**: `subprocess` 呼び出し時の実行ファイル名などをフルパス可能にするか検証を追加。

この計画を「承認（修正案対応）」するか、「このままPush」するかお知らせください。
