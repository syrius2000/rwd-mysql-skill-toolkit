# Query Note

status: validated
validated_at: 2026-07-18 (JST)
assumptions_confirmed: EVENTDATE で最古判定 / Ct05 = `CH_t05_covid_vaccine`

> 曖昧プロンプトから本ノートに到達するまでの思考経過: [ambiguity_resolution_trace.md](./ambiguity_resolution_trace.md)

## 分析目的

- 自然文の問い: Ct05 テーブルから、各症例の一番古いレコードを抽出したい
- 目的: 症例（患者）ごとに初回イベント相当の1行を得る
- 対象 DB: `VACCINE`（ローカル MySQL 8.4）

## データセットの粒度

- 一行の単位: 1 症例（`PATIENTNO`）あたり 1 行
- 主 ID: `PATIENTNO`
- 期間: 期間未指定（全期間）

## テーブル候補

| テーブル | 役割 | 採用理由 | 確認状況 |
|---|---|---|---|
| `CH_t05_covid_vaccine` | 主テーブル | ローカル DB で `Ct05` / `t05` に該当する唯一のテーブル。COVID ワクチン問診・接種イベント | `DESCRIBE`・件数確認済 |

**注記**: `information_schema` 上に `Ct05` という名前のテーブルは存在しない。ユーザー指定の Ct05 は `CH_t05_covid_vaccine`（VACCINE DB）として解釈した。別名・別 DB の場合は要確認。

## JOIN 方針

- 結合キー: なし（単一テーブル）
- 日付条件: なし（全期間）
- 最古判定: `EVENTDATE` 昇順。同値時は `更新日時` → `DEPARTMENTCODE` で1行に決定（`ROW_NUMBER`）
- 粒度が増える箇所: なし

## 検証結果

| 観点 | SQL | 結果 | 判断 |
|---|---|---|---|
| 総件数（元） | validation #1 | 26,492 行 | OK |
| ユニーク ID（元） | validation #1 | 18,154 症例 | OK |
| NULL | validation #1 | PATIENTNO 欠損 0 | OK |
| 本 SQL 件数 | validation #3 | 18,154 行 | OK（症例数と一致） |
| 重複 | validation #4 | 0 件 | OK |
| 同 EVENTDATE タイ | validation #5 | 1 症例のみ（タイブレークで解消） | OK |
| 期間 | validation #1 | EVENTDATE 2021-04-02 〜 2023-12-12 | 記録済 |

## 未確認リスク

- `Ct05` が `CH_t05_covid_vaccine` 以外を指す場合、本 SQL は再設計が必要
- 「最古」の定義が `更新日時` ベースである場合、並び順の変更が必要
- QNAP MariaDB（192.168.0.110:3307）側のスキーマ・件数は未検証

## 分析系への引き渡し

- 出力先: `sql/validated/ct05_oldest_per_case/main_query.sql`
- 推奨する次スキル: 必要に応じて `mysql-table-cardinality` で他テーブルとの ID 重なり確認
- 注意点: 1 症例 1 行。初回接種問診の属性のみが必要な場合は列を絞ること
