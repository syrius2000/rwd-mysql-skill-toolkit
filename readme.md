# IDE用スキル管理リポジトリ

このリポジトリは、各種IDE（Cursor, Antigravity）で使用するスキルを一元管理します。

## リポジトリ構造

```
.
├── .agent/skills/          # Antigravity 用スキル
├── .cursor/skills/         # Cursor 用スキル（正本）
├── .github/
│   ├── commands/           # Gemini Code Assist 設定（toml）
│   └── workflows/          # GitHub Actions（Gemini CI/CD）
├── .gemini/                # Gemini 設定
├── docs/
│   ├── Artifacts/          # 生成ドキュメント
│   ├── Reference/          # 参照ドキュメント（同期ルール等）
│   ├── Archive/            # アーカイブ
│   ├── plans/              # 計画書
│   └── superpowers/        # 拡張機能関連
├── flat_file_mysql/        # フラットファイル MySQL 関連資産
└── tests/                  # テスト
```

## 管理スキル一覧

`.agent/skills` と `.cursor/skills` の両方に同一の7スキルを配置しています。

### データ連携・操作スキル

| スキル名 | 概要 |
|----------|------|
| `flat-file-mysql-overview` | CP932 CSV を MySQL に投入する一連の流れ（ステップ 1→2→3）のオーバービュー |
| `flat-file-mysql-ddl-generation` | CP932 CSV から DDL 用サンプル SQL とレコード数・重複数レポートを生成（ステップ 1） |
| `flat-file-mysql-load-validation` | 完成版 SQL の作成支援・DB 名指定・指定 DB への実行・件数比較（ステップ 2〜3） |
| `mysql-er-diagram` | 指定 MySQL DB のテーブルから辞書 CSV をフル再生成し、Draw.io XML と PlantUML の ER 図を生成 |
| `mysql-table-cardinality` | 指定テーブルのカラム一覧・総行数・カーディナリティを CSV/JSON で出力 |
| `mysql-entity-matrix` | 指定 DB 内の全テーブルを横断し、特定 ID の存在フラグ `[0, 1]` マトリックスを生成 |

### セキュリティ

| スキル名 | 概要 |
|----------|------|
| `security-vulnerability-check` | ソースコード（Python, SQL, R, C++ 等）の脆弱性チェック（SQL インジェクション、OS コマンドインジェクション、パストラバーサル等） |

## 同期ルール

- **正本**: `.cursor/skills` ディレクトリ
- **同期先**: `.agent/skills`（Antigravity 用）
- シンボリックリンクは使用しない

詳細な同期ルール（対象ファイル一覧、置換ルール、コマンド例）は以下を参照：

- [Artifact_012_cursor_agent_skills_sync_rule_0301_1200.md](docs/Reference/Artifact_012_cursor_agent_skills_sync_rule_0301_1200.md)

### 同期対象の概要

| 種別 | 同期方法 |
|------|----------|
| スクリプト・プロンプト | `.cursor` → `.agent` へ内容完全一致でコピー |
| SKILL.md（flat-file-mysql-* 3本, mysql-table-cardinality） | `.cursor` を正本として編集後、パス置換と description 補記で `.agent` 用を派生 |
| mysql-er-diagram | `.cursor/skills` と `.agent/skills` の両方に同一内容で配置。改修時は両方を更新 |

## GitHub Actions（Gemini Code Assist）

`.github/workflows/` 配下に Gemini Code Assist 連携の GitHub Actions を配置しています。

| ワークフロー | 用途 |
|-------------|------|
| `gemini-review.yml` | PR レビュー |
| `gemini-triage.yml` | Issue トリアージ |
| `gemini-scheduled-triage.yml` | 定時 Issue トリアージ |
| `gemini-invoke.yml` | Gemini 呼び出し |
| `gemini-dispatch.yml` | ディスパッチ |

設定ファイルは `.github/commands/` 配下の `.toml` ファイルで管理しています。
