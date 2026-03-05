# IDE用スキル管理リポジトリ

このリポジトリは、各種IDE（Cursor, Antigravity）で使用するスキルを管理します。

## 管理スキル一覧

### データ連携・操作スキル

- **フラットファイルMySQL DDL生成 (`flat-file-mysql-ddl-generation`)**: フラットファイルからMySQLのDDLを生成します。
- **フラットファイルMySQLロード検証 (`flat-file-mysql-load-validation`)**: MySQLへのデータロード結果を検証します。
- **フラätファイルMySQL概要 (`flat-file-mysql-overview`)**: MySQLにロードされたフラットファイルの概要を把握します。
- **MySQL ER図生成 (`mysql-er-diagram`)**: 指定されたデータベースのテーブル・カラム情報を基に、PlantUML形式のER図を生成します。
- **MySQLテーブルカーディナリティ分析 (`mysql-table-cardinality`)**: 指定されたテーブルのカラム一覧、総行数、カーディナリティを分析し、CSV/JSON形式で出力します。

### OpenSpecによるSDD（Specification Driven Development）支援スキル

OpenSpecは、仕様書に基づいた開発を支援する一連のスキル群です。

- **`openspec-onboard`**: プロジェクトの初期設定を行います。
- **`openspec-new-change`**: 新しい変更を開始します。
- **`openspec-ff-change`**: 設計書、提案書、タスクリストを一括で生成します。
- **`openspec-continue-change`**: 設計書、提案書、タスクリストを対話形式で順次作成します。
- **`openspec-apply-change`**: 生成されたタスクに基づき、AIがコードを実装します。
- **`openspec-verify-change`**: 実装された変更を検証します。
- **`openspec-sync-specs`**: 仕様書を同期します。
- **`openspec-explore`**: 仕様書を探索します。
- **`openspec-archive-change`**: 完了した仕様書やタスクをアーカイブします。
- **`openspec-bulk-archive-change`**: 複数の仕様書やタスクを一括でアーカイブします。

```mermaid
graph TD
    A[Start: 新規変更タスク開始<br/>/opsx-new-change] --> B{成果物生成方法を選択};
    B --> C[一括生成<br/>/opsx-ff-change];
    B --> D[対話形式で順次生成<br/>/opsx-continue-change];
    C --> E[成果物<br/>(proposal, specs, design, tasks)];
    D --> E;
    E --> F[タスクに基づき実装<br/>/opsx-apply-change];
    F --> G[実装を検証<br/>/opsx-verify-change];
    G --> H[アーカイブ<br/>/opsx-archive-change];
```

### セキュリティ

- **セキュリティ脆弱性チェック (`security-vulnerability-check`)**: コードの脆弱性をチェックします。

## 同期ルール

スキル定義の正本は `.cursor/skills` ディレクトリに配置します。`.agent/skills`（Antigravity用）への同期ルールについては、[docs/Reference/Artifact_012_cursor_agent_skills_sync_rule_0301_1200.md](docs/Reference/Artifact_012_cursor_agent_skills_sync_rule_0301_1200.md) を参照してください。
