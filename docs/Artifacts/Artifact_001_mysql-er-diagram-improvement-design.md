作成日時: 2026-03-20 00:10 (JST)
作成者: AI Agent

# mysql-er-diagram スキル改修（仕様確定）

## 目的
`mysql-er-diagram` スキルを改修し、指定 MySQL DB からテーブルの ER 図を生成する際に、
1) Draw.io XML と PlantUML（.md）の双方を常に出力し、
2) テーブル/リレーションの意味付けや FK 結線を CSV 辞書を通じて制御できるようにし、
3) Draw.io XML の色が環境差で崩れないようにスタイルを固定する。

## スコープ（確定）
- 対象: `TABLE_TYPE = 'BASE TABLE'` の物理テーブルのみ（ビュー等は除外）
- 出力: **常に** Draw.io XML と PlantUML（.md）を両方生成（デフォルトで出し分け機能は持たない）
- 辞書: `[DB名]_dictionary.csv` は **都度フル再生成（C）** とする
  - 毎回 DB メタデータから再計算し、辞書 CSV は新規に全件上書き出力する
  - 手で修正して保持したい場合は、別運用（例: バックアップ/別辞書）を想定する
  - ※本スキーマ上は必要に応じて `foreign_key_target` を利用する（生成物の結線根拠）
- 実行環境: `.cursor` と `.agent` の双方に改修を適用する
  - スクリプトも `generate_er.py` をそれぞれのディレクトリへ **実ファイルとして配置**（`ln` 等は使わない）
  - `SKILL.md` も両方を同仕様に更新

## 辞書 CSV スキーマ（正）
ファイル: `[DB名]_dictionary.csv`

| カラム名 | 説明 |
|---|---|
| `table_name` | 物理テーブル名 |
| `logical_table_name` | 論理テーブル名（未設定時は `table_name` を使用） |
| `column_name` | 物理カラム名 |
| `logical_column_name` | 論理カラム名（未設定時は `column_name` を使用） |
| `data_type` | データ型（例: `int`, `varchar(50)`） |
| `is_primary_key` | PK なら `TRUE`、それ以外は `FALSE` |
| `is_foreign_key` | 参照先を持つ FK 相当なら `TRUE`、それ以外は `FALSE` |
| `foreign_key_target` | `参照先テーブル.参照先カラム`（例: `inpatient.PTID-nyuuinn`）。未設定時は空 |

## 実行フロー（確定）
1. `--db` の DB 名検証と出力ディレクトリ正規化
2. `INFORMATION_SCHEMA` から
   - `TABLE_TYPE = 'BASE TABLE'` のテーブル一覧取得
   - `COLUMNS` / `KEY_COLUMN_USAGE` 等でカラム・PK/FK 相当を取得
3. 取得したメタデータから辞書 CSV の全行を組み立て、`[DB名]_dictionary.csv` を全件上書き出力
4. 辞書 CSV の内容に基づき
   - Draw.io XML を生成（ノード=テーブル、エッジ=`foreign_key_target`）
   - PlantUML を生成（`@startuml`〜`@enduml`）
5. `--out` で指定したディレクトリに CSV / XML / MD の3種を保存

## Draw.io 配色・スタイル固定（確定）
Draw.io XML 内で、テーブルノードとエッジについて `fillColor` / `strokeColor` / `fontColor` / `strokeWidth` 等をスクリプト側で明示し、
テンプレートや環境差に依存しない見た目を保証する。

## 実装方針（ディレクトリ配置）
- `.cursor/skills/mysql-er-diagram/` と `.agent/skills/mysql-er-diagram/` の両方に以下を配置する。
  - `SKILL.md`（同一仕様・同一手順）
  - `scripts/generate_er.py`（同一内容を実ファイルとしてコピー）
- `ln` 等のリンク技術は使用しない。
