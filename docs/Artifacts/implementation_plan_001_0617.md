# agentic-evidence-analysis を正本にする移行計画

created: 2026-06-17 00:00 (JST)
author: AI Agent (GPT-5)

## 目的

カテゴリカル分析・エビデンス分析の同名5スキルを `rwd-mysql-skill-toolkit` から `agentic-evidence-analysis` へ集約し、今後は後者を正本として運用する。

## 対象

- `vcd-pass0-consultation`
- `vcd-bayesian-evidence-analysis`
- `vcd-categorical-analysis`
- `questionnaire-batch-analysis`
- `vcd-categorical-reporting`

## 方針

1. `agentic-evidence-analysis` を正本にする。
2. まず同名5スキルの内容を `agentic-evidence-analysis` 側へ移す。
3. `README.md`、`AGENTS.md`、関連参照文書を正本前提に整える。
4. `rwd-mysql-skill-toolkit` 側は参照案内を中心に整理し、正本の役割を持たせない。

## 実施手順

1. 両リポジトリの同名スキル差分を確認する。
2. `agentic-evidence-analysis` 側に必要なスキル、参照文書、テストを反映する。
3. `README.md` と `AGENTS.md` を正本前提に更新する。
4. 必要なテストと整合性確認を実施する。
5. 両リポジトリで commit と push を行う。

## 完了条件

- `agentic-evidence-analysis` が正本として読める状態になっている。
- 同名5スキルの内容が正本側にまとまっている。
- README と AGENTS の案内が新しい運用に一致している。
- 変更内容を push 済みである。
