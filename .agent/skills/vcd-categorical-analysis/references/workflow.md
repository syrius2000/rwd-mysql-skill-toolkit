# ワークフロー（3ステップ方式）

```mermaid
sequenceDiagram
    participant User
    participant AI as AI Agent
    participant R as analysis.R
    participant Rmd as dashboard.Rmd / report.Rmd
    participant Out as skill_out/vcd_categorical/

    User->>AI: 分析依頼（実行フェーズ）

    Note over AI,R: Step 1: 集計
    AI->>R: analysis.R --render [--config ...]
    R->>Out: categorical_results.json, summary_*.json

    Note over AI: Step 2: AI 考察
    AI->>Out: executive_summary.md

    Note over AI,Rmd: Step 3: レポート（既定 dashboard）
    AI->>Rmd: render → dashboard.html
    Out->>User: 完了報告
```

## テンプレ選択

| テンプレ | 用途 |
| :--- | :--- |
| `dashboard.Rmd` | **既定**。モザイク・AIサマリー統合ダッシュボード |
| `report.Rmd` | 代替。gt/DT 中心のレガシー形式 |

## オプション: render_config

水準数が多い場合は Step 1 前に `--profile` で `data_profile.json` を確認し、`render_config.json` を生成して `--config` を付与する。
