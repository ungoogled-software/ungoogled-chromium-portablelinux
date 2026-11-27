#!/bin/bash
set -euo pipefail

clone=false
use_gentoo_source_tar=false
if [[ "${1:-}" == "-c" ]]; then
    clone=true && shift
elif [[ "${1:-}" == "-g" ]]; then
    use_gentoo_source_tar=true && shift
fi
crubit_rev="${1:-d757594f6f7ac27c0cf9c8ea63d9136f8e1f77ae}"

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/shared.sh"

setup_paths

# clean out/ directory before build
rm -rf "${_src_dir}/out" || true

fetch_sources "$clone" "$use_gentoo_source_tar" "$crubit_rev"
apply_patches
apply_domsub
install_rustup
write_gn_args
fix_tool_downloading
setup_toolchain
gn_gen
maybe_build
