## Why

CP932 の CSV を MySQL 8.0 へ投入する際、手作業での DDL 作成・重複除去・エンコーディング検証が煩雑である。テキスト CSV から MySQL 8.0 用 DDL を自動生成し、取り込み前の検証（エンコーディング確認、重複検出・削除、件数比較バリデーション）を一括で行い、データ品質と作業効率を向上させる。

## フロー概要（3 ステップ）

1. **ステップ 1**: CSV を読み、エンコードを確認し、数行の SQL ファイル（DDL 用サンプル）を作成する。あわせて対象 CSV のレコード数・重複数を確認しレポートする（複数 CSV 対応）。エンコーディング検証は CLI／パイプライン内で標準ライブラリ（codecs 等）により実施する。
2. **ステップ 2**: ステップ 1 で作成したファイルと保存されたプロンプト（例: SQLImportAndDedupe.prompt.md）に従い、CSV をインポートする完成版 SQL を作成する。対象 DB 名は指定を求める。
3. **ステップ 3**: ステップ 2 で完成した SQL を、指定した対象 DB へインポート（実行）する。

## What Changes

- AnotherPJ のコード・ドキュメントを参照し、CP932 CSV 用の DDL 生成・検証・投入の一連の仕組みを整える
- CP932 CSV から MySQL 8.0 互換 DDL を自動生成する **Skill.md** を 2 分割（DDL 生成 / 投入・バリデーション）で作成し、その Skill を使って CSV を MySQL に投入する流れを確立する
- フラットファイル内の重複レコード検出・削除とレポート出力（複数 CSV 対応）
- エンコーディング検証（CP932 前提。パイプライン内で標準ライブラリにより実施）
- フラットファイル件数・重複件数・DB 投入件数の比較バリデーション
- 当 change 配下に **validation.md** を置き、バリデーション手順・フローを明文化する

## Capabilities

### New Capabilities

- `csv-encoding-validation`: CP932 判定と検証
- ステップ 1: CSV を読みエンコード確認し、数行の DDL 用サンプル SQL ファイルを作成。レコード数・重複数をレポート（複数 CSV 対応）。CH_t01 / CH_t05 形式を参考にし、続けて SQLImportAndDedupe.prompt.md 等の保存プロンプトに従い完成版 SQL を作成するための入力を用意する
- `duplicate-detection`: 重複レコード検出
- `deduplication`: 重複削除処理
- `ddl-generation`: MySQL 8.0 用 DDL 生成
- `load-validation`: 元件数・重複件数・投入結果の比較バリデーション
- `skill-docs`: 2 分割 Skill（B: DDL 生成 / C: 投入・バリデーション）とオーバービュー
- `validation-doc`: validation.md による手順・フローの文書化

### Modified Capabilities

- （なし）

## Impact

- Python / SQL / CLI ツールの追加
- Skill.md（2 分割 + オーバービュー）の追加
- validation.md の追加（当 change 配下）
- MySQL 8.0 クライアントの利用
- 新規 CSV 取り込みパイプラインの導入（3 ステップ: サンプル SQL＋レポート → 完成版 SQL（DB 名指定）→ 対象 DB へ実行）
