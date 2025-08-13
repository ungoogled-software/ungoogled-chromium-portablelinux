#!/bin/bash
set -euxo pipefail

_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd ../.. && pwd)"
_cache_tar="${_base_dir}/.github/cache/build-cache.tar.zst"

if [ -f "${_cache_tar}" ]; then
    mkdir -p "${_base_dir}"
    zstd -d -c "${_cache_tar}" | tar -xf - -C "${_base_dir}"
else
    echo "No cache archive found to import (${_cache_tar}). Skipping." >&2
fi
