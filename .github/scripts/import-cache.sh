#!/bin/bash
set -euxo pipefail

# disk space on free runners is limited, let's make some
# space while waiting for build tree extraction to finish
sudo rm -rf /usr/local/lib/android \
            /usr/local/.ghcup \
            /usr/lib/jvm \
            /usr/lib/google-cloud-sdk \
            /usr/lib/dotnet \
            /usr/share/swift &

_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd ../.. && pwd)"
_cache_tar="${_base_dir}/.github/cache/build-cache.tar.zst"

if [ -f "${_cache_tar}" ]; then
    mkdir -p "${_base_dir}"
    zstd -d -c "${_cache_tar}" | tar -xf - -C "${_base_dir}"

    # we no longer need the tarball once it's
    # extracted, so let's get rid of it
    rm "${_cache_tar}"
    wait
else
    echo "No cache archive found to import (${_cache_tar}). Skipping." >&2
fi
