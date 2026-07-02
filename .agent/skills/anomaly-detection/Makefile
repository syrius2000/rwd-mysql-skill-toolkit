.PHONY: install test lint format synth infer clean

install:
	python -m pip install -U pip
	python -m pip install -e '.[dev]'

test:
	pytest

lint:
	ruff check src tests scripts

format:
	ruff format src tests scripts

synth:
	python scripts/generate_synth.py --output data/synthetic_edc.csv --n 500

infer:
	python scripts/infer.py --input data/synthetic_edc.csv --output outputs/anomaly_results.jsonl

clean:
	rm -rf .pytest_cache .ruff_cache build dist *.egg-info outputs/*.jsonl
