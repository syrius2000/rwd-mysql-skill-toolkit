---
name: anomaly-detection
description: EDC/RWD data anomaly and outlier detection skill for RBQM and central monitoring.
license: MIT
metadata:
  author: Yamaguchi Manabu
  version: "0.1.0"
---

# EDC/RWD Anomaly Detection Skill

EDC/eCRF export や RWD/eSource データ、監査証跡、query log、site-level risk indicator を対象に、ルールベース、robust statistics、Isolation Forest、LOF、LLM review を組み合わせて異常候補を優先順位付けするスキルです。

詳細な設計と運用手順は、同階層の [README.md](README.md) と `docs/` を参照してください。

## 主要な入口

- Python entrypoint: `anomaly_detection.pipeline:run_detection`
- CLI: `scripts/infer.py`, `scripts/train.py`, `scripts/generate_synth.py`
- 設定: `configs/`
- スキーマ: `docs/schemas/`

## 注意事項

- 本スキルは異常の確定ではなく、レビュー優先順位付けを目的とします。
- 自動的な医療判断や query 発行は行いません。
- PHI/PII をログに出さず、監査可能な出力を残してください。
