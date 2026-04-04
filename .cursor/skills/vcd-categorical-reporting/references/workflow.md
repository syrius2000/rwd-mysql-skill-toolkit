# VCD 分析ワークフロー（2パス方式）

## シーケンス図

```mermaid
sequenceDiagram
    participant AI as AI Agent
    participant R as analysis.R
    participant Out as skill_out/

    Note over AI,R: Pass 1: プロファイリング（軽量）
    AI->>R: analysis.R --profile
    R->>Out: data_profile.json
    Out->>AI: 次元数・水準数・セル数・疎密度を確認

    Note over AI: AI がデータ特性に基づき表示パラメータを決定
    Note over AI: 例: 水準集約・層選択・表示モード

    Note over AI,R: Pass 2: 本生成（パラメータ付き）
    AI->>R: analysis.R --render --config render_config.json
    R->>Out: JSON, CSV, gt HTML, DT HTML, PNG
    Out->>AI: 成果物読取

    Note over AI: AI 判断フェーズ
    AI->>AI: 第1段階 主効果残差の俯瞰
    AI->>AI: 第2段階 交互作用の洞察
    AI->>AI: 層別判断 前面配置する層を選択

    Note over AI: レポート構成
    AI->>Out: vcd_analysis_report.md 作成
```

## render_config.json の判断ガイドライン

| データ特性 | 判断ポイント | 推奨設定 |
| :--- | :--- | :--- |
| 合計セル数 > 200 | ビジーになりやすい | `collapse_below_n: 5` で低頻度セルを集約 |
| 水準数 > 8 | ラベルが潰れやすい | `max_levels_per_var: 8` で上位のみ表示 |
| 3-way で層数 > 5 | gt マトリックスが多すぎ | `strata_to_render` で2-3層に絞る |
| 疎密度(sparsity) < 0.5 | ゼロセルが多い | モデル収束に注意、注釈を追加 |
