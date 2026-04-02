# Architectural Steering

## Codebase Layout
- `.agent/skills/`: 各種AIスキルのファイル一式（`SKILL.md`, `templates/`, `references/`等）が収められる中核ディレクトリ。
- `.agent/workflows/`: `kiro-spec-init` 等、Kiro式AIエージェント開発プロセスを実現・規定するワークフローコマンド群。
- `.agent/specs/`: CC-SDDに基づき新規機能やスキル改修を行う際の要件定義、設計、タスク進捗を管理するファイル群（機能ごとにディレクトリ分割）。
- `.agent/rules/`: システム全体やエージェントの振る舞いを定義する各種ルールファイル。
- `.agent/steering/`: プロジェクト全体の方針をナビゲートするこの Steering ファイル（不変の知識ベース）。
- `docs/artifacts/`: AIエージェントが作成する各種レポートや解析結果などの固定化アウトプット先。
- `skill_out/`: 各種スキル（RやSQL）が実行された際の中間データ（JSONやCSVなど）が一時的あるいは永続的に保存される先。

## Patterns
- **Skill構成**: 最上位に `name`, `description`, `metadata` を持つ YAML フロントマターを備えた `SKILL.md` を配置し、役割と出力仕様を定義する。
- **CC-SDD Spec構成**: 機能ごとのディレクトリ配下に `spec.json`（メタデータ/現状ステータス）、`requirements.md`（要件定義）、`design.md`（設計・アーキテクチャ）、`tasks.md`（実装タスク分割一覧）の形式でフェーズ分割される。
