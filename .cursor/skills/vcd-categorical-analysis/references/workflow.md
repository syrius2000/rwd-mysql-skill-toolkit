# ワークフロー（2パス方式）

## 典型的な流れ（シーケンス）

```mermaid
sequenceDiagram
    participant User
    participant AI as AI Agent
    participant R as analysis.R
    participant Out as skill_out/vcd_categorical/

    User->>AI: データ指定＆分析依頼

    Note over AI,R: Pass 1: プロファイリング（軽量）
    AI->>R: analysis.R --profile
    R->>Out: data_profile.json
    Out->>AI: 次元数・水準数・セル数・疎密度を確認

    Note over AI: AI がデータ特性に基づき表示パラメータを決定
    AI->>AI: render_config.json を生成

    Note over AI,R: Pass 2: 本生成（パラメータ付き）
    AI->>R: analysis.R --render --config render_config.json
    R->>Out: JSON, CSV, gt HTML, DT HTML, PNG
    Out->>AI: 成果物読取

    Note over AI: AI 判断フェーズ（vcd-categorical-reporting）
    AI->>AI: 第1段階 主効果残差の俯瞰
    AI->>AI: 第2段階 交互作用の洞察
    AI->>AI: 層別判断 前面配置する層を選択

    Note over AI: レポート構成
    AI->>Out: vcd_analysis_report.md 作成
    Out->>User: 報告
```

## 判断木

1. **変数は 4 個以上のクロスが必要か？**
   - はい → **本スキル範囲外**。次元削減・質問の分割・部分集合を検討。
2. **次元は 2 か 3 か？**
   - 2 → `analysis.R` の 2 変数パート。
   - 3 → 3-way 表・層別 2-way・対数線形（`glm-gnm-goodness.md`）。
3. **順序ありリッカートを統計的にフル活用したいか？**
   - はい → **`ordinal-likert-advanced.md`**。
   - いいえ → 名義として vcd・対数線形可。
4. **DB から列・件数を先に確認したいか？**
   - はい → **`mysql-table-cardinality`** でスキーマ・濃度数を確認。

## 連携

| 隣接タスク | 使うもの |
| :--- | :--- |
| MySQL の件数・カーディナリティ | `mysql-table-cardinality` |
| AI 判断レポート生成 | `vcd-categorical-reporting`（本スキルの後続） |
| R 運用の再現性 | ユーザーの `r-robust-workflow` 等 |
