# SQL 成果物

DB 探索スキルおよび Query 作成支援スキルで作った、再利用可能な SQL を置く場所です。

## ディレクトリ方針

| ディレクトリ | 用途 |
|---|---|
| `drafts/` | 作業中の SQL。未完成・未検証の可能性がある。 |
| `validated/` | 件数・NULL・重複・期間・カテゴリ値などの検証を通過した SQL。 |
| `examples/` | 若手向けの教材例・再利用パターン。 |

## トピックごとの標準ファイル

各トピックは次の構成にします。

```text
sql/drafts/<topic>/
  main_query.sql
  validation_query.sql
  query_note.md
```

必要に応じて、判断根拠の記録として `ambiguity_resolution_trace.md` を同じディレクトリに置いてよい。

検証結果が意図した粒度・分析目的と一致することをユーザーが確認したあと、トピックを `drafts/` から `validated/` へ移す。移したあとの正本は `validated/` とし、同名の `drafts/` は残さない。

## query_note.md に書くこと

`query_note.md` には次を記録する。

- 自然文の分析目的
- データセットの粒度（1行の単位）
- 主 ID
- 日付方針
- JOIN の根拠
- 検証結果
- 残リスク
- 推奨する次の分析スキル
