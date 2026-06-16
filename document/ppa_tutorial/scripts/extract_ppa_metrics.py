#!/usr/bin/env python3
import csv
import json
import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
CASES = [
    "ariane133",
    "ariane136",
    "bp",
    "bp_be",
    "bp_fe",
    "bp_multi",
    "bp_quad",
    "swerv_wrapper",
]


def read_json(path: Path) -> dict:
    return json.loads(path.read_text())


def parse_overflow(grt_log: Path):
    text = grt_log.read_text(errors="replace")
    match = re.search(r"Total\s+\d+\s+\d+\s+\d+\.\d+%\s+\d+\s+/\s+\d+\s+/\s+(\d+)", text)
    if match:
        return int(match.group(1))
    return None


def main() -> int:
    rows = []

    for design in CASES:
        root = REPO_ROOT / "OpenROAD-PPA-evaluation" / "logs" / "nangate45" / design / "ReMaP"
        final_json = root / "6_report.json"
        route_json = root / "5_2_route.json"
        grt_log = root / "5_1_grt.log"

        missing = [str(path.relative_to(REPO_ROOT)) for path in (final_json, route_json, grt_log) if not path.exists()]
        if missing:
            print(f"SKIP {design}: missing {', '.join(missing)}")
            continue

        final = read_json(final_json)
        route = read_json(route_json)

        row = {
            "Dataset": design,
            "Method": "ReMaP",
            "Wirelength": route.get("detailedroute__route__wirelength"),
            "WNS": final.get("finish__timing__setup__ws"),
            "TNS": final.get("finish__timing__setup__tns"),
            "Power": final.get("finish__power__total"),
            "#overflow": parse_overflow(grt_log),
            "DRC_errors": route.get("detailedroute__route__drc_errors"),
        }
        rows.append(row)
        print(row)

    out = REPO_ROOT / "my_remap_metrics_all.csv"
    with out.open("w", newline="") as file:
        writer = csv.DictWriter(
            file,
            fieldnames=["Dataset", "Method", "Wirelength", "WNS", "TNS", "Power", "#overflow", "DRC_errors"],
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
