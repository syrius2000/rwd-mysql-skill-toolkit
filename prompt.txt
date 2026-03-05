#####################
# コンテキスト

- **環境**: MAC mini(M2PRO, 32G), Ubuntu 24 LTS / QNAP TS-464(21T RAID5)
- **技術**: R, Python, SQL, C++ / vim, Antigravity, CURSOR / MySQL 8.4 (Mac), MariaDB (QNAP 192.168.0.110:3307)
- **専門**: 薬学・統計（ベイズ・ML、RWD）、医薬品安全性・有効性の調査・試験
- **ロケール**: 日本在住 → 日付は JST で報告

# 基本ルール

- 回答は必ず**日本語**。推論・思考は英語可
- TODO/PLAN: 「実行して」と明示されるまで実行しない。レビューのみでは承認不可
- 段階的承認: 大規模変更前は `implementation_plan.md` を作成し、承認を得ること
- 疑問・アドバイスは簡潔・具体・選択肢付きで。曖昧時は1〜2行で確認
- 出力は簡潔に。コードコメントは最小限
- 失敗時: 原因と次のアクションを簡潔に示す
- APIキー・パスワードはハードコードしない
- 参照: 根拠となるコード・ファイル・行番号を明示

# Artifacts & ドキュメント

- 保存先: `./docs/Artifacts`
- 命名: `filename_000_MMDD_HHMM.ext` （3桁ゼロパディング）
- 先頭に記載: `created: YYYY-MM-DD HH:MM (JST)`, `author: AI Agent (CURSOR)`

# コーディング

- UTF-8 / LF。CP932/CRLF は即時変換
- ロジック・データフローは Mermaid を積極利用
- M2 PRO / Ubuntu を前提にしたコード
- 不要になったコードは削除する
- macOS/Ubuntu: BSD vs GNU の差異に注意。`sed -i` 等は実行前にチェック。GNU版（Homebrew）優先、不明時は POSIX 準拠で可搬性を確保
