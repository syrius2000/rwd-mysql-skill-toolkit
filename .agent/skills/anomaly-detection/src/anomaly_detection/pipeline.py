from __future__ import annotations

from typing import Any

import pandas as pd

from .audit import make_audit_record
from .detectors import EnsembleDetector
from .explain import build_explanation
from .features import robust_mad_scores
from .rules import describe_rule_hits, evaluate_rules


def _label(score: float, config: dict) -> str:
    thresholds = config.get("thresholds", {})
    if score >= float(thresholds.get("critical", 0.80)):
        return "critical"
    if score >= float(thresholds.get("warning", 0.55)):
        return "warning"
    return "normal"


def run_detection(df: pd.DataFrame, config: dict) -> dict[str, Any]:
    """Run multi-stage anomaly detection for EDC/RWD data."""
    df = df.copy()
    if "record_id" not in df.columns:
        df["record_id"] = [f"row-{i}" for i in range(len(df))]

    rules = evaluate_rules(df, config)
    robust = robust_mad_scores(df, config) if config.get("robust_stats", {}).get("enabled", True) else pd.Series(0.0, index=df.index)

    detector = EnsembleDetector(config).fit(df)
    model_scores = detector.score_samples(df)

    fusion = config.get("score_fusion", {})
    final_score = (
        float(fusion.get("rule_weight", 0.40)) * rules["rule_score"]
        + float(fusion.get("robust_weight", 0.15)) * robust
        + float(fusion.get("iforest_weight", 0.25)) * model_scores.get("iforest", pd.Series(0.0, index=df.index))
        + float(fusion.get("lof_weight", 0.20)) * model_scores.get("lof", pd.Series(0.0, index=df.index))
    ).clip(0, 1)

    results: list[dict[str, Any]] = []
    for idx, row in df.iterrows():
        contributions = {
            "rule_score": float(rules.loc[idx, "rule_score"]),
            "robust_mad": float(robust.loc[idx]),
        }
        for name, series in model_scores.items():
            contributions[name] = float(series.loc[idx])
        score = float(final_score.loc[idx])
        label = _label(score, config)
        hits = describe_rule_hits(rules.loc[idx])
        results.append({
            "record_id": str(row["record_id"]),
            "score": score,
            "label": label,
            "triggered_rules": hits,
            "model_contributions": contributions,
            "explanation": build_explanation(score, label, hits, contributions),
        })

    results = sorted(results, key=lambda x: x["score"], reverse=True)
    top_k = int(config.get("output", {}).get("top_k", len(results)))
    results = results[:top_k]
    summary = {
        "n_records": int(len(df)),
        "n_returned": int(len(results)),
        "n_warning_or_critical": int(sum(r["label"] != "normal" for r in results)),
        "audit": make_audit_record(config=config, input_rows=len(df)),
    }
    return {"results": results, "summary": summary}
