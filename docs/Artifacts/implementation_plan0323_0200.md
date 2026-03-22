created: 2026-03-23 02:00 (JST)
author: AI Agent (Gemini 2.0 Pro)

# セキュリティチェックおよびIssue改善計画 (pre-merge to Main)

Main ブランチへマージする前に行うべきセキュリティ点検結果と、リポジトリ内で発見されたその他のIssueについての改善計画です。

## User Review Required
> [!IMPORTANT]
> この計画書の内容をご確認いただき、問題なければ「承認 (Approve) します」とご指示をお願いいたします。承認後、記載された改善策を自動で適用します。

## 1. セキュリティチェック結果
`security-vulnerability-check` スキルのガイドラインに基づき、Python/SQL等に関する静的コードの点検（マニュアルレビュー）を実施しました。
※ `bandit` による静的解析は環境権限（macOSのキャッシュパーミッション）により失敗したため、重要な `subprocess` / `f-string` 使用箇所を中心に重点的にレビューしています。

- **OSコマンドインジェクション**: `subprocess.run` において、`shell=True` を使用せず、リスト形式で引数展開を行っているため安全です。
- **SQLインジェクション (動的クエリ)**: `flat-file-mysql` や `mysql-entity-matrix` にて、コマンドラインから受け取った引数（DB名、テーブル名など）に対して `validate_identifier` 関数等を用いたバリデーション（英数字・アンダースコア等への限定）や、バッククオート等への手動エスケープが正しく実装されています。
- **総合判定**: 現時点のコードベースにおいて、深刻なインジェクション脆弱性やパストラバーサルのリスクは見当たらず、**安全にマージ可能な状態**です。

## Proposed Changes (その他の Issue 改善)
リポジトリ点検において、主に以下の2つのIssueを発見しましたので、マージ前に改善を実施します。

### Issue 1: `.gitignore` の定義漏れ
直近の改修により、各スキルの出力先ディレクトリが `skill_out/` に変更されていますが、`.gitignore` には以前の `skill_output/*` しか記載されておらず、誤ってGit管理下に混入するリスクがあります。
- **改善策**: `.gitignore` に `skill_out/` ルールを追記します。

#### [MODIFY] .gitignore
```diff
--- a/.gitignore
+++ b/.gitignore
@@ -47,6 +47,8 @@
 
 skill_output/*
 # 補足: Git は空のディレクトリを追跡しないため、リポジトリに skill_output を残す場合は .gitkeep を追跡する
 !skill_output/.gitkeep
+skill_out/*
+!skill_out/.gitkeep
```

### Issue 2: スキル定義内の不要なディレクトリの削除 (vcd-categorical-analysis)
スキル開発・テスト時の残骸として、`vcd-categorical-analysis` スキルの `templates/` 配下に `skill_output/` や `skill_out/` といった出力用ディレクトリが混入しています。
これらは本来リポジトリ（プロジェクト）のルートに出力されるべきものであり、スキル構成ファイル（テンプレート）内に含めておくのは不適切です。また、これが現在の `git status` 実行時のパーミッションエラー（Operation not permitted）の直接的な原因となっています。
- **改善策**: ご指摘の通り完全に不要であるため、`.cursor/skills/` および `.agent/skills/` の両方から、これらの該当ディレクトリを削除（`rm -rf`）します。

#### [DELETE] .cursor/skills/vcd-categorical-analysis/templates/skill_output/
#### [DELETE] .cursor/skills/vcd-categorical-analysis/templates/skill_out/
#### [DELETE] .agent/skills/vcd-categorical-analysis/templates/skill_output/
#### [DELETE] .agent/skills/vcd-categorical-analysis/templates/skill_out/

## Verification Plan
### Automated Tests
- 改善適用後、再度 `git status` を実行し、Working tree clean になっていること、およびパーミッションエラーが記録されないことを確認します。
- `skill_out/` へテスト用の空ファイルを作成し、Gitに追跡されない(`git status`に出ない)ことの確認を行います。
