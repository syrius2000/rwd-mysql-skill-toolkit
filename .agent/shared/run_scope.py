"""Run-scoped output helpers for Python skill CLIs (mirrors .agent/shared/run_scope.R)."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

RUN_META_INTERFACE_VERSION = "1.0"
JST = ZoneInfo("Asia/Tokyo")


@dataclass(frozen=True)
class RunIdResult:
    run_id: str
    source: str


def default_run_id_auto() -> str:
    return datetime.now(JST).strftime("%Y%m%d_%H%M%S")


def run_id_short16(run_id: str) -> str:
    return run_id[:16]


def run_output_dir_from_root(out_root: Path | str, run_id: str) -> Path:
    return Path(out_root) / f"run_{run_id_short16(run_id)}"


def run_output_dir_from_slug(out_root: Path | str, dir_slug: str) -> Path:
    """Return ``<out_root>/run_<dir_slug>/`` (collision suffixes included)."""
    return Path(out_root) / f"run_{dir_slug}"


def sha256_file(path: Path | str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def resolve_run_id(
    explicit: str | None = None,
    *,
    input_path: Path | str | None = None,
) -> RunIdResult:
    if explicit is not None:
        e = explicit.strip()
        if e:
            if e.lower() == "auto":
                rid = default_run_id_auto()
                return RunIdResult(run_id=rid, source="auto")
            return RunIdResult(run_id=e, source="explicit")
    return RunIdResult(run_id=default_run_id_auto(), source="auto")


def input_hash_meta(input_path: Path | str | None) -> str | None:
    if input_path is None:
        return None
    p = Path(input_path)
    if p.is_file():
        return sha256_file(p)
    return None


def write_run_meta(
    out_root: Path | str,
    run_output_dir: Path | str,
    skill: str,
    run_id: str,
    input_data_path: str | None = None,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    out_root_p = Path(out_root).resolve()
    run_dir_p = Path(run_output_dir).resolve()
    run_dir_p.mkdir(parents=True, exist_ok=True)
    meta: dict[str, Any] = {
        "interface_version": RUN_META_INTERFACE_VERSION,
        "skill": skill,
        "run_id": run_id,
        "run_id_short": run_id if len(run_id) <= 16 else run_id_short16(run_id),
        "out_root": str(out_root_p),
        "run_output_dir": str(run_dir_p),
        "input_data": str(Path(input_data_path).resolve()) if input_data_path else None,
        "created_at": datetime.now(JST).strftime("%Y-%m-%dT%H:%M:%S%z"),
    }
    if extra:
        meta.update(extra)
    meta_path = run_dir_p / "run_meta.json"
    meta_path.write_text(
        json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return meta


def prepare_run_output_dir(
    out_root: Path | str,
    skill: str,
    *,
    run_id: str | None = None,
    input_path: Path | str | None = None,
) -> tuple[Path, RunIdResult]:
    rid = resolve_run_id(run_id, input_path=input_path)
    out_root_p = Path(out_root)
    prefix = run_id_short16(rid.run_id)
    run_dir = out_root_p / f"run_{prefix}"
    collision = 2
    while run_dir.exists():
        run_dir = out_root_p / f"run_{prefix}_{collision}"
        collision += 1
    run_dir.mkdir(parents=True, exist_ok=True)
    dir_slug = run_dir.name.removeprefix("run_")
    rid = RunIdResult(run_id=dir_slug, source=rid.source)
    extra: dict[str, Any] = {}
    ih = input_hash_meta(input_path)
    if ih:
        extra["input_hash_sha256"] = ih
    write_run_meta(
        out_root_p,
        run_dir,
        skill,
        rid.run_id,
        str(input_path) if input_path else None,
        extra=extra or None,
    )
    return run_dir, rid
