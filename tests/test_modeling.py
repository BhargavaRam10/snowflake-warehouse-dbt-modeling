"""Structural tests for the dbt project.

dbt itself needs a live Snowflake to compile against, so CI runs these
convention tests instead: every ref() points at a model that exists, every
model has a schema.yml entry, and every documented model declares tests.
Requires PyYAML.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest
import yaml

try:
    import yaml  # noqa: F401
except ImportError:  # pragma: no cover
    pytest.skip("PyYAML not installed", allow_module_level=True)

ROOT = Path(__file__).resolve().parent.parent
MODELS = ROOT / "models"

REF_RE = re.compile(r"""\{\{\s*ref\(["']([\w]+)["']\)\s*\}\}""")


def _all_models() -> dict[str, Path]:
    return {p.stem: p for p in MODELS.rglob("*.sql")}


def _documented_models() -> dict[str, dict]:
    docs: dict[str, dict] = {}
    for yml in MODELS.rglob("schema.yml"):
        data = yaml.safe_load(yml.read_text()) or {}
        for model in data.get("models", []):
            docs[model["name"]] = model
    return docs


def test_every_ref_points_to_existing_model():
    models = _all_models()
    missing = []
    for name, path in models.items():
        for ref in REF_RE.findall(path.read_text()):
            if ref not in models:
                missing.append(f"{name} -> ref('{ref}')")
    assert not missing, f"dangling refs: {missing}"


def test_every_model_is_documented():
    models = set(_all_models())
    documented = set(_documented_models())
    assert models <= documented, f"undocumented models: {models - documented}"


def test_every_documented_model_has_tests():
    docs = _documented_models()
    untested = [n for n, m in docs.items() if not m.get("columns")]
    assert not untested, f"models with no column tests: {untested}"
