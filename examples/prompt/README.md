# 新人研修用 デモプロンプト一覧と検証手順
created: 2026-06-30 16:20 (JST)
author: AI Agent (Composer)

本ディレクトリは、新人研修スライド [`slides.md`](../../slides.md) に対応するAIエージェントの各「スキル」を実際に動かす（または成果物を参照する）ための標準プロンプト集です。

---

## 1. プロンプト一覧

| ファイル名 | 対象スキル | 内容 |
| :--- | :--- | :--- |
| [`01_mysql-er-diagram.md`](./01_mysql-er-diagram.md) | `mysql-er-diagram` | `example/mf.db` からER図およびデータ辞書を生成する |
| [`02_flat-file-mysql-overview.md`](./02_flat-file-mysql-overview.md) | `flat-file-mysql-overview` | CP932 CSV（合成RWD）をMySQLに投入する（実環境では一部静的参照） |
| [`03_mysql-create-query-support.md`](./03_mysql-create-query-support.md) | `mysql-create-query-support` | 自然文の要望からSQLite用のSpending集計クエリ群を生成する |
| [`04_mysql-table-cardinality.md`](./04_mysql-table-cardinality.md) | `mysql-table-cardinality` | `mf.db` に対応するカラム濃度レポート（静的成果物）を参照する |
| [`05_mysql-entity-matrix.md`](./05_mysql-entity-matrix.md) | `mysql-entity-matrix` | 合成RWDにおける `PatientID` のテーブル間横断マトリクス（静的成果物）を参照する |
| [`10_vcd-pass0-titanic.md`](./10_vcd-pass0-titanic.md) | `vcd-pass0-consultation` | Titanic（小標本）のデータ検分と分析設計（Pass 0）を実行する |
| [`11_vcd-pass0-titanic100x.md`](./11_vcd-pass0-titanic100x.md) | `vcd-pass0-consultation` | Titanic×100（大標本）のデータ検分と分析設計（Pass 0）を実行する |
| [`12_vcd-bayesian-titanic.md`](./12_vcd-bayesian-titanic.md) | `vcd-bayesian-evidence-analysis` | Titanic（小標本）のベイズ推論・考察・ダッシュボード（Pass 1〜3）を実行する |
| [`13_vcd-bayesian-titanic100x.md`](./13_vcd-bayesian-titanic100x.md) | `vcd-bayesian-evidence-analysis` | Titanic×100（大標本）のベイズ推論・考察・ダッシュボード（Pass 1〜3）を実行する |
| [`14_vcd-categorical-titanic.md`](./14_vcd-categorical-titanic.md) | `vcd-categorical-analysis` | Titanic（小標本）のカテゴリカル分析とエグゼクティブサマリー、ダッシュボードを生成する |
| [`15_compare-titanic-vs-100x.md`](./15_compare-titanic-vs-100x.md) | `vcd-bayesian-evidence-analysis` | 生TitanicとTitanic 100倍の分析結果を対比し、「P値の呪縛」を説明する |

---

## 2. 研修実演・検証手順

### 必須デモ

研修では、以下の2テーマを必須デモとします。

1. **ER図作成デモ**:
   [`01_mysql-er-diagram.md`](./01_mysql-er-diagram.md) を使い、`example/mf.db` からER図とデータ辞書を生成します。
2. **生Titanic vs Titanic 100倍の対比デモ**:
   [`15_compare-titanic-vs-100x.md`](./15_compare-titanic-vs-100x.md) を使い、同じセル比率でもサンプルサイズが100倍になると、統計指標の見え方がどう変わるかを説明します。前提成果物が未生成の場合は、[`10_vcd-pass0-titanic.md`](./10_vcd-pass0-titanic.md) → [`11_vcd-pass0-titanic100x.md`](./11_vcd-pass0-titanic100x.md) → [`12_vcd-bayesian-titanic.md`](./12_vcd-bayesian-titanic.md) → [`13_vcd-bayesian-titanic100x.md`](./13_vcd-bayesian-titanic100x.md) の順に実行してから比較します。

### オプションデモ

上記以外のプロンプトは、時間や受講者の関心に応じて選択するオプションデモとします。

### A. DB構築系デモ（MySQLなし環境）
研修当日はMySQLが利用できないため、一部のMySQL専用スキルは **静的成果物の参照** を行い、SQL作成・実行は **SQLite (`example/mf.db`)** を用いてローカルでライブ実演します。

1. **ER図の生成 (Live)**:
    [`01_mysql-er-diagram.md`](./01_mysql-er-diagram.md) のプロンプトをAIに投入し、`example/skill_out/` にER図（XML/Markdown）とデータ辞書が生成されることを確認します。
2. **クエリ作成とSQLite実行 (Live)**:
    [`03_mysql-create-query-support.md`](./03_mysql-create-query-support.md) のプロンプトでAIにSQLを生成させます。その後、`example/sql/run_query.sh` を使用して `example/mf.db` に対しクエリを実行し、実際の集計値を取得します。
3. **静的成果物の参照 (Static)**:
    [`04_mysql-table-cardinality.md`](./04_mysql-table-cardinality.md) および [`05_mysql-entity-matrix.md`](./05_mysql-entity-matrix.md) のプロンプトを投げ、あらかじめ用意された `example/skill_out/` 配下の静的レポートが適切に参照・解説されることを確認します。

### B. 分析系デモ（4-Passパイプライン）
Rがインストールされている環境であれば、すべてのPass（0〜3）を実際に動かすことができます。

1. **Pass 0 (Live)**:
    [`10_vcd-pass0-titanic.md`](./10_vcd-pass0-titanic.md) / [`11_vcd-pass0-titanic100x.md`](./11_vcd-pass0-titanic100x.md) を投げ、`example/analysis/` に `analysis_config.json` やデータ検分結果が生成されることを確認します。
2. **Pass 1〜3 (Live/Static)**:
    [`12_vcd-bayesian-titanic.md`](./12_vcd-bayesian-titanic.md) / [`13_vcd-bayesian-titanic100x.md`](./13_vcd-bayesian-titanic100x.md) を投げ、統計計算の実行、考察の自動執筆、およびインタラクティブ・ダッシュボード（`dashboard.html`）が `example/skill_out/vcd_bayesian/` 配下に正しく生成されることを確認します。（※重い処理のため、大標本は事前生成された成果物の閲覧を推奨）

---

## 3. 統計解説：「P値の呪縛」対比カンペ

スライド 49行目の「サンプルサイズが大きい（N > 2,000）と、わずかな偏りでも『統計的に有意』と見えやすい」という問題を、Titanicデータを用いて実演します。

| 項目 | `titanic.csv` (小標本) | `titanic_100x.csv` (大標本) |
| :--- | :--- | :--- |
| **総度数 N** | 2,201 件 | 220,100 件 (セル比率は同一) |
| **カイ二乗検定 p値** | $p < 0.001$ (極めて有意) | $p < 0.0001$ (さらに極小化) |
| **Bayes Factor (BF)** | 解釈可能な適正値 (例: $BF = 1.2 \times 10^3$) | 桁違いに巨大化 ($BF > 10^{20}$) |
| **Evidence Score** | 強いエビデンス（実質的意義あり） | 非常に強いエビデンス（ただし大標本補正が必要） |

### 研修メッセージ

* **従来のP値検定の問題点**:
    Nが20万を超えると、現実的には「ほぼ同一の割合（比率の差が0.1%未満）」であっても、P値は容易に「有意（p < 0.05）」を示してしまいます。これが「P値の呪縛」です。
* **4-Pass パイプラインでの解決**:
    Pass 1〜2（ベイズ推論とAI考察）を通すことで、単なるサンプルサイズ依存の「有意」ではなく、**エビデンスの強さ（Evidence Score）や効果量**を考慮した客観的な評価ができるようになり、新人でもノイズに惑わされない本質的な分析設計が可能になります。
