"""Generate dbt seed CSVs from the repo-01 synthetic data.

Seeds let reviewers run `dbt build` against a Snowflake trial without any
ingestion step: the warehouse models are exercised end-to-end on the same
synthetic domain. Run: python data/generate_seeds.py
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GEN = Path.home() / "workspace" / "github-starter-kit" / "repos" / \
    "01-end-to-end-data-pipeline" / "data" / "generate_synthetic_data.py"
SEEDS = ROOT / "seeds"

TABLES = {
    "routes.csv": "routes_raw",
    "pickups.csv": "pickups_raw",
}


def main() -> None:
    SEEDS.mkdir(exist_ok=True)
    # Generate the synthetic samples with the sibling repo's generator.
    subprocess.run([sys.executable, str(GEN)], check=True)
    samples = GEN.parent / "samples"
    for src, seed_name in TABLES.items():
        shutil.copy(samples / src, SEEDS / f"{seed_name}.csv")
    print(f"Wrote seeds: {sorted(p.name for p in SEEDS.glob('*.csv'))}")


if __name__ == "__main__":
    main()
