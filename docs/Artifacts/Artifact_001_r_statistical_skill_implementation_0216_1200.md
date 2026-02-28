created: 2025-02-16 12:00 JST
author: AI Agent

# 実施事項・終了報告：R-statistical-analysis スキル作成

## 概要

既存の `statistical-analysis` スキルをベースに、R 実装特化の `r-statistical-analysis` スキルを新規作成した。

## 実施事項

| # | 項目 | 内容 |
|---|------|------|
| 1 | 作成場所 | `~/.cursor/skills/r-statistical-analysis/SKILL.md` |
| 2 | 構成 | 単一 SKILL.md（257 行、500 行以内） |
| 3 | パッケージロード | `pacman::p_load()` 使用（未インストールは自動インストール） |
| 4 | コード置換 | Python → R へ全コード例を置換 |
| 5 | 使用パッケージ | zoo（移動平均）、base R（scale, quantile, IQR） |

## 置換したコードブロック

| セクション | 元 (Python) | 置換先 (R) |
|-----------|-------------|-----------|
| Moving average | `df['ma_7d'] = df['metric'].rolling(...)` | `rollapplyr(df$metric, 7, mean, partial=TRUE)` |
| Z-score | `(df['value'] - mean) / std` | `as.numeric(scale(df$value))` |
| IQR | `quantile()`, `Q1 - 1.5*IQR` | `quantile()`, `IQR()` |
| Percentile | `df['value'].quantile(0.01)` | `quantile(df$value, c(0.01, 0.99))` |
| Growth rates | 一般式 | R 式（`log()`, `^`） |

## 終了報告

- [x] ディレクトリ作成
- [x] SKILL.md 作成
- [x] R コードへの置換
- [x] pacman::p_load() 方針の適用
- [x] YAML 更新（name, description）
- [x] パッケージ管理の前提を本文冒頭に記載

**ステータス**: 完了
