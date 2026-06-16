# questionnaire-cross-question-synthesis Specification

## Purpose

`questionnaire-batch-analysis`で複数設問を横断して総括し、重要設問、解釈保留、実務的示唆、次アクションを整理する要件を定義する。

## Requirements

### Requirement: 設問横断総括の生成
`questionnaire-batch-analysis`は、設問別`report.html`と`summary.csv`を維持したまま、複数設問を横断して分析結果を総括するMarkdown成果物をMUST生成できなければならない。

#### Scenario: 横断総括を生成する
- **WHEN** `questionnaire-batch-analysis`が複数設問の一括分析を完了する
- **THEN** エージェントは`summary.csv`と設問別成果物を根拠に、重要設問、実務的示唆、解釈保留、次アクションを含む横断総括Markdownを生成できる

#### Scenario: 設問別成果物を置き換えない
- **WHEN** 横断総括が生成される
- **THEN** 既存の`summary.csv`、設問別`report.html`、設問別図表は削除または置換されず、横断総括は上位索引として追加される

### Requirement: 単純なP値ランキングの禁止
設問横断総括は、P値だけで設問を順位付けしてはならず、効果量、残差方向、セル数、設問タイプ、エラー状態、解釈保留を合わせてMUST扱わなければならない。

#### Scenario: 有意だが効果量が小さい設問を扱う
- **WHEN** `summary.csv`に統計的には有意だが効果量または実務的意味が小さい設問が含まれる
- **THEN** 横断総括は当該設問を強い実務的発見として断定せず、大標本効果または解釈保留として説明する

#### Scenario: エラーまたは設定不整合がある設問を扱う
- **WHEN** `summary.csv`に`status=error`相当の行、設定不整合、または解析不能な設問が含まれる
- **THEN** 横断総括は当該設問を結果解釈から除外し、修正が必要な設問として明示する

### Requirement: 設問タイプ別の解釈
設問横断総括は、`nominal_2way`、`likert_2way`、`nominal_3way`などの設問タイプに応じて、比較、方向性、層別解釈の扱いをMUST区別しなければならない。

#### Scenario: Likert設問を総括する
- **WHEN** 横断対象に`likert_2way`設問が含まれる
- **THEN** 横断総括は順序性を踏まえた解釈を行い、名義カテゴリと同じ表現で単純に扱わない

#### Scenario: 3-way設問を総括する
- **WHEN** 横断対象に`nominal_3way`設問が含まれる
- **THEN** 横断総括は2-wayの単純な関連として断定せず、層別または交互作用の観点を含めて説明する

### Requirement: 横断総括の完了報告
`questionnaire-batch-analysis`の完了報告は、設問別成果物に加えて横断総括の有無、保存先、主要な保留事項をMUST示さなければならない。

#### Scenario: 横断総括を含む完了報告
- **WHEN** questionnaire一括分析が横断総括まで完了する
- **THEN** エージェントは`summary.csv`、設問別`report.html`、横断総括Markdownの保存先と、重要設問および保留事項の概要を報告する

#### Scenario: 横断総括が生成できない
- **WHEN** 入力不足、全設問エラー、または必要な成果物欠落により横断総括を生成できない
- **THEN** エージェントは完了報告で理由、必要な修正、再実行すべき手順を明示する
