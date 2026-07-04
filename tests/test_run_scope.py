"""Tests for .agent/shared/run_scope.py"""

from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[1]
SHARED = REPO_ROOT / ".agent" / "shared"
sys.path.insert(0, str(SHARED))

import run_scope as rs  # noqa: E402


def test_run_id_short16():
    assert rs.run_id_short16("abcdefghijklmnopqrs") == "abcdefghijklmnop"


def test_run_output_dir_from_root():
    out = rs.run_output_dir_from_root("/tmp/out", "unit_test_slug_xyz")
    assert out == Path("/tmp/out/run_unit_test_slug_x")


def test_resolve_run_id_explicit():
    r = rs.resolve_run_id("my_custom_id")
    assert r.run_id == "my_custom_id"
    assert r.source == "explicit"


def test_resolve_run_id_auto_keyword():
    r = rs.resolve_run_id("auto")
    assert r.source == "auto"
    assert len(r.run_id) == 15  # %Y%m%d_%H%M%S


def test_resolve_run_id_default_is_timestamp():
    r = rs.resolve_run_id(None)
    assert r.source == "auto"
    assert len(r.run_id) == 15


def test_prepare_run_output_dir_creates_meta():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        run_dir, rid = rs.prepare_run_output_dir(
            root,
            "test-skill",
            run_id="explicit_run_001",
        )
        assert run_dir.name == "run_explicit_run_001"
        assert (run_dir / "run_meta.json").is_file()
        meta = json.loads((run_dir / "run_meta.json").read_text(encoding="utf-8"))
        assert meta["skill"] == "test-skill"
        assert meta["run_id"] == "explicit_run_001"


def test_two_default_runs_do_not_collide_when_run_id_differs(monkeypatch):
    monkeypatch.setattr(rs, "default_run_id_auto", lambda: "20260704_120000")
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        d1, _ = rs.prepare_run_output_dir(root, "t")
        d2, _ = rs.prepare_run_output_dir(root, "t")
        assert d1 != d2
        assert d1.is_dir() and d2.is_dir()


def test_collision_meta_matches_directory():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        rs.prepare_run_output_dir(root, "t", run_id="fixed_run_id")
        run_dir, rid = rs.prepare_run_output_dir(root, "t", run_id="fixed_run_id")
        assert run_dir.name == "run_fixed_run_id_2"
        assert rid.run_id == "fixed_run_id_2"
        assert rs.run_output_dir_from_slug(root, rid.run_id) == run_dir
        meta = json.loads((run_dir / "run_meta.json").read_text(encoding="utf-8"))
        assert meta["run_id"] == "fixed_run_id_2"
        assert meta["run_output_dir"] == str(run_dir.resolve())
        assert meta["run_id_short"] == "fixed_run_id_2"


def test_input_hash_meta(tmp_path: Path):
    p = tmp_path / "data.csv"
    p.write_text("a,b\n1,2\n", encoding="utf-8")
    h = rs.input_hash_meta(p)
    assert h is not None
    assert len(h) == 64
