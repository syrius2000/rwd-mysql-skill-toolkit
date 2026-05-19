# 同名 Skill 一本化 実施計画

created: 2026-05-31 (JST)
author: Codex

## 目的

`rwd-mysql-skill-toolkit` と `agentic-evidence-analysis` に同名で存在する VCD/Questionnaire 系 5 Skill を、toolkit 側を正本として常に同一内容に保つ。

## 現状

- 正本: `rwd-mysql-skill-toolkit/.agent/skills/`
- サテライト: `agentic-evidence-analysis/.agent/skills/`
- 対象 Skill:
  - `questionnaire-batch-analysis`
  - `vcd-bayesian-evidence-analysis`
  - `vcd-categorical-analysis`
  - `vcd-categorical-reporting`
  - `vcd-pass0-consultation`
- 現時点では対象 5 Skill は `diff -qr` で一致済み。
- MySQL 系 Skill と `security-vulnerability-check` は toolkit 側だけの Skill であり、agentic 側へ同期しない。

## 実施内容

1. toolkit に `scripts/sync-agentic-evidence-skills.sh` を追加する。
2. `--check` で対象 5 Skill の差分確認のみを実行できるようにする。
3. 通常実行では対象 5 Skill だけを `rsync -a --delete` で agentic 側へ同期する。
4. 同期後に `diff -qr` を再実行し、不一致が残れば失敗させる。
5. toolkit の `AGENTS.md` と `README.md` に同期ルールを追記する。
6. agentic の `AGENTS.md` と `README.md` に「同名 5 Skill は toolkit から同期する」旨を補強する。

## 検証

toolkit 側:

```bash
./scripts/sync-agentic-evidence-skills.sh --check
```

agentic 側:

```bash
Rscript --vanilla tests/test_vcd_bayesian_analysis_config_schema.R
Rscript --vanilla tests/test_vcd_bayesian_help.R
Rscript --vanilla tests/test_vcd_bayesian_vars_freq_fei.R
Rscript --vanilla tests/test_questionnaire_batch_smoke.R
```

## 採用ルール

今後同名 Skill に差分が出た場合は、agentic 側を直接正本化しない。差分を評価し、採用する変更は toolkit 側に取り込んでから同期する。
