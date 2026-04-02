# ワークフロー

## 典型的な流れ（シーケンス）

```mermaid
sequenceDiagram
  participant User
  participant R as R Script
  participant Out as skill_out_vcd_categorical
  participant AI as AI Agent (Evaluation)
  participant Report as AI Artifact (3 chapters)
  
  User->>AI: データ指定＆レポート作成依頼
  AI->>R: `analysis.R` 実行
  R->>Out: JSON(評価指標)、CSV(残差)、PNG(図表)
  Out->>AI: 抽出結果の取得
  AI->>AI: 第1段階(主効果残差)、第2段階(2-way残差) 解釈
  AI->>AI: 第一章(評価)、第二章(残差)、第三章(図表) を構成
  AI->>Report: レポート (Markdown) 出力
  Report->>User: 報告
```

## 判断木

1. **変数は 4 個以上のクロスが必要か？**  
   - はい → **本スキル範囲外**。次元削減・質問の分割・部分集合を検討。
2. **次元は 2 か 3 か？**  
   - 2 → `analysis.R` または `report.Rmd` の 2-way パート（`xtabs` 2 変数）。  
   - 3 → 3-way 表・層別 2-way・対数線形 `m0/m1/m2`（`glm-gnm-goodness.md`）。
3. **順序ありリッカートを統計的にフル活用したいか？**  
   - はい → **`ordinal-likert-advanced.md`**（序数回帰・polychoric 等）。  
   - いいえ（カテゴリ頻度としてよい）→ 名義／`ordered` factor として vcd・対数線形可。
4. **DB から列・件数を先に確認したいか？**  
   - はい → **`mysql-table-cardinality`** でスキーマ・濃度数を確認してから CSV 抽出。

## 連携

| 隣接タスク | 使うもの |
|------------|----------|
| MySQL の件数・カーディナリティ | `mysql-table-cardinality` |
| 個人の R 運用（再現性・セッション） | ユーザーの `r-robust-workflow` 等があれば data 取得〜ここまでの前処理に利用 |
