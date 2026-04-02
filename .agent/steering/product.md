# Product Steering

## Mission & Vision
当プロジェクトは、Antigravity（Gemini 3 Pro 等のAIエージェント）および各種IDE（Cursorなど）で利用する「各種スキル（Skill）」を定義・管理するリポジトリです。R言語、SQL、Pythonなどを駆使した解析から、AIが中間出力を解釈してインサイトを含む成果物（Artifact）を生成するまでの、「自律的な分析アシスタントワークフロー」を実現します。

## Target Audience
- 自分自身（統計専門家・プログラミング実務家であるユーザー）
- AIエージェント（Antigravity, Cursor等）がコンテキストを共有するため

## Core Features & Concepts
- **Kiro / CC-SDD**: 要件定義 (Requirements) → 設計 (Design) → タスク (Tasks) → 実装 (Implementation) のフェーズを厳格に守るAI駆動開発（CC-SDD）を採用している。
- **データ解析スキルの高度化**: `vcd-categorical-analysis` や `mysql-table-cardinality` など、統計モデリングやDB照会を行う専門スキル。
- **AI主導の解釈・レポーティング**: スクリプトにすべてを出力させるのではなく、スクリプトは小粒の中間データ（JSONやCSV等）を出力し、AI自身が最終評価レポート（Artifact）を章立て構成するアーキテクチャを目指す。
