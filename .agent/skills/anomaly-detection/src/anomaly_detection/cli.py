from __future__ import annotations

import argparse

from .config import load_config
from .io import read_table, write_csv, write_jsonl
from .pipeline import run_detection


def main() -> None:
    parser = argparse.ArgumentParser(description="Run EDC/RWD anomaly detection.")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--config", default=None)
    parser.add_argument("--format", choices=["jsonl", "csv"], default="jsonl")
    args = parser.parse_args()

    df = read_table(args.input)
    cfg = load_config(args.config)
    out = run_detection(df, cfg)
    if args.format == "jsonl":
        write_jsonl(out["results"], args.output)
    else:
        write_csv(out["results"], args.output)
    print(out["summary"])


if __name__ == "__main__":
    main()
