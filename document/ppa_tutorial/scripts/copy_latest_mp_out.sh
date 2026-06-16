#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${repo_root}"

copy_one() {
  local source_case="$1"
  local target_design="$2"
  local latest

  latest="$(find "ReMaP/install/results" -path "*/${source_case}/*/mp_out" -type f | sort | tail -n 1 || true)"

  if [[ -z "${latest}" ]]; then
    echo "SKIP ${source_case}: no mp_out found"
    return 0
  fi

  mkdir -p "OpenROAD-PPA-evaluation/results/nangate45/${target_design}/ReMaP"
  cp "${latest}" "OpenROAD-PPA-evaluation/results/nangate45/${target_design}/ReMaP/mp_out"
  echo "COPIED ${source_case} -> ${target_design}: ${latest}"
}

copy_one "ariane133" "ariane133"
copy_one "ariane136" "ariane136"
copy_one "black_parrot" "bp"
copy_one "bp_be" "bp_be"
copy_one "bp_fe" "bp_fe"
copy_one "bp_multi" "bp_multi"
copy_one "bp_quad" "bp_quad"
copy_one "swerv_wrapper" "swerv_wrapper"

echo
echo "Current PPA mp_out files:"
find "OpenROAD-PPA-evaluation/results/nangate45" -path "*/ReMaP/mp_out" -type f | sort
