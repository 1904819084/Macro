#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
design="${1:-}"

if [[ -z "${design}" ]]; then
  echo "Usage: bash document/ppa_tutorial/scripts/run_ppa_docker.sh <design>"
  echo "Designs: ariane133 ariane136 bp bp_be bp_fe bp_multi bp_quad swerv_wrapper"
  exit 1
fi

case "${design}" in
  ariane133)
    design_config="./designs/nangate45/ariane133/config.mk"
    ;;
  ariane136)
    design_config="./designs/nangate45/ariane136/config.mk"
    ;;
  bp|black_parrot)
    design="bp"
    design_config="./designs/nangate45/black_parrot/config.mk"
    ;;
  bp_be)
    design_config="./designs/nangate45/bp_be_top/config.mk"
    ;;
  bp_fe)
    design_config="./designs/nangate45/bp_fe_top/config.mk"
    ;;
  bp_multi)
    design_config="./designs/nangate45/bp_multi_top/config.mk"
    ;;
  bp_quad)
    design_config="./designs/nangate45/bp_quad/config.mk"
    ;;
  swerv_wrapper)
    design_config="./designs/nangate45/swerv_wrapper/config.mk"
    ;;
  *)
    echo "Unknown design: ${design}"
    echo "Designs: ariane133 ariane136 bp bp_be bp_fe bp_multi bp_quad swerv_wrapper"
    exit 1
    ;;
esac

if [[ ! -f "${repo_root}/OpenROAD-PPA-evaluation/results/nangate45/${design}/ReMaP/mp_out" ]]; then
  echo "Missing mp_out: OpenROAD-PPA-evaluation/results/nangate45/${design}/ReMaP/mp_out"
  echo "Run first: bash document/ppa_tutorial/scripts/copy_latest_mp_out.sh"
  exit 1
fi

docker_bin="${DOCKER_BIN:-docker}"
if ! command -v "${docker_bin}" >/dev/null 2>&1; then
  if [[ -x "/opt/homebrew/bin/docker" ]]; then
    docker_bin="/opt/homebrew/bin/docker"
  else
    echo "docker command not found. Install/start Docker, or set DOCKER_BIN=/path/to/docker"
    exit 1
  fi
fi

platform_args=()
machine_name="$(uname -m)"
if [[ "${machine_name}" == "arm64" || "${machine_name}" == "aarch64" ]]; then
  platform_args=(--platform linux/amd64)
fi

echo "Running PPA for ${design}"
echo "DESIGN_CONFIG=${design_config}"

"${docker_bin}" run --rm "${platform_args[@]}" \
  -v "${repo_root}:/work" \
  -w /work/OpenROAD-PPA-evaluation \
  openroad/orfs:latest \
  bash -lc "source /OpenROAD-flow-scripts/env.sh; unset FLOW_HOME DESIGN_HOME PLATFORM_HOME WORK_HOME UTILS_DIR SCRIPTS_DIR TEST_DIR; make do-2_4_floorplan_macro DESIGN_CONFIG=${design_config} OPENROAD_EXE=/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad YOSYS_CMD=/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys; make do-macroflow DESIGN_CONFIG=${design_config} OPENROAD_EXE=/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad YOSYS_CMD=/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys"
