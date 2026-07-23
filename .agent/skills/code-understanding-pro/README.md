# code-understanding-pro 日本語版

既存コードの理解、レビュー、QA、ドキュメント化、リファクタリング支援を行うAgent Skillです。軽い質問はチャットで返し、深い解析はMarkdownレポートとして保存します。

## 内容

```text
code-understanding-pro/
├── SKILL.md
├── README.md
├── VERSION
├── LICENSE.txt
├── manifest.json
├── references/
│   ├── qiita-code-reading-pyramid.md
│   ├── review-severity-guide.md
│   ├── refactoring-safety-checklist.md
│   └── test-first-caveats.md
├── assets/
│   ├── output-template-quick.md
│   ├── output-template-full.md
│   ├── output-template-review.md
│   ├── output-template-refactoring.md
│   ├── mermaid-patterns.md
│   ├── docstring-template-python.md
│   └── docstring-template-r.md
├── scripts/
│   ├── collect_code_context.py
│   └── write_report.py
└── examples/
    ├── example-prompts.md
    └── expected-output-skeleton.md
```

## 使い方

Agent Skills互換の環境では、このディレクトリをSkill配置場所にコピーしてください。

例：

```bash
mkdir -p ~/.agent/skills
cp -R code-understanding-pro ~/.agent/skills/
```

プロジェクト配下に置く場合の例：

```bash
mkdir -p .agent/skills
cp -R code-understanding-pro .agent/skills/
```

## 想定される依頼例

- この関数を5段階で説明して
- このPRをQAして
- このコードの副作用を洗い出して
- 初学者向けに処理フローを説明して
- DocStringとMarkdown仕様を書いて
- 挙動を変えないリファクタリング案を出して

## 設計思想

このSkillは、レビュー指摘を先に出すのではなく、次の順にコード理解を深めます。

1. 文脈把握
2. 概要理解
3. 詳細追跡
4. 深い設計理解
5. 活用

軽い質問ではQuick Mode、深い解析ではFull Mode、レビュー/QAではReview Modeを使います。

## 出力方式

| モード | 出力 |
|---|---|
| Quick | チャットのみ |
| Full | `code_understanding_report.md` とチャット要約 |
| Review | `code_review_report.md` とチャット要約 |
| Documentation | `code_documentation.md` とチャット要約 |
| Refactoring | `refactoring_proposal.md` とチャット要約 |

深い解析の成果物は、`skill_out/code_understanding/<target>/run_<id>/` に保存します。同一runの再実行では上書きしません。

```bash
python3 scripts/write_report.py \
  --mode full \
  --target src/example.py \
  --content-file /tmp/code_understanding_report.md \
  --output-root ./skill_out/code_understanding \
  --run-id example
```

保存前に一般的なAPIキー、パスワード、Bearerトークン、秘密鍵は伏せ字にします。詳細な出力契約は `SKILL.md` の「出力契約」を参照してください。
