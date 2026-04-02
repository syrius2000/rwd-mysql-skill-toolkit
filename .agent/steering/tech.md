# Technical Steering

## Tech Stack
- **R**: データ処理、高度な統計解析。パッケージロードには必ず `pacman::p_load()` を使用する。
- **MySQL / SQL**: データベースのスキーマ確認、DDL生成、Cardinality解析用。
- **Python / C++**: 必要に応じた高パフォーマンス処理など。
- **Markdown / Mermaid**: 設計書、レポート（Artifact）、ロジックやデータフロー等の可視化に多用する。

## Engineering Principles
- **CC-SDDフローの遵守**: `kiro-spec-init`, `kiro-spec-reqs`, `kiro-spec-design`, `kiro-spec-tasks`, `kiro-spec-impl` の承認フローに基づき、いきなりの実装を避ける。
- **OS間差異への厳密な注意**: macOS (BSD系コマンド) と Ubuntu (GNU系コマンド) の挙動・オプションの差異に留意して CLI 操作を行う。
- **Git/GitHubの積極利用**: `gh` コマンド類を用いた積極的なバージョン管理および連携を行うこと。
- **成果物と推論の言語分離**: Artifact等の作業ドキュメントの推論（Reasoning）のプロセスは「英語」で行うが、生成・表示される具体的な成果物の文章は「日本語」を基本とする。
- **Artifact要件**: Artifactファイルには適切な出力フォルダ（`./docs/artifacts/`など）、ファイル名（`# Artifact_000_...`）、作成日(JST)、作成者（LLM名）の記載を欠かさない。
- **モジュラーパイプライン**: バッチでの一気通貫実行より、段階的（結果JSON出力 → AI解釈）なパイプラインを好む。
