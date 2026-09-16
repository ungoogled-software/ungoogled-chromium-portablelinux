#!/bin/bash
set -euo pipefail

clone=false
if [[ "${1:-}" == "-c" ]]; then
    clone=true
fi

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/shared.sh"

setup_paths

# clean out/ directory before build
rm -rf "${_src_dir}/out" || true

fetch_sources "$clone"
apply_patches
apply_domsub
write_gn_args
fix_tool_downloading
setup_toolchain
gn_gen
maybe_build
