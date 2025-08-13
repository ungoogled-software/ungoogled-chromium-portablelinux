#!/bin/bash
set -euxo pipefail

_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd ../.. && pwd)"
_cache_tar="${_base_dir}/.github/cache/build-cache.tar.zst"

pushd "${_base_dir}" >/dev/null

if [ ! -d "build" ]; then
    echo "ERROR: No build directory found."
    exit 1
fi

mkdir -p "$(dirname "${_cache_tar}")"

rm -rf "build/download_cache"

# create archive via stream to avoid tar flag incompatibilities
tar -cf - "build" | zstd -f -T0 -3 -o "${_cache_tar}"

popd >/dev/null
