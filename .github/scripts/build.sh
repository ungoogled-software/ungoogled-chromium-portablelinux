#!/bin/bash
set -euxo pipefail

. "/repo/scripts/shared.sh"

setup_paths

if [ "$_prepare_only" = true ]; then
    fetch_sources false
    apply_patches
    apply_domsub
    write_gn_args
    fix_tool_downloading
    setup_toolchain
    gn_gen
else
    _task_timeout=18000
    cd "$_src_dir"

    set +e
    timeout -k 5m -s INT "${_task_timeout}"s ninja -C out/Default chrome chromedriver
    rc=$?
    set -e

    if [ "${_gha_final}" != "true" ] && [ "$rc" -eq 124 ]; then
        echo "Task timed out after ${_task_timeout}s; continuing in next run."
        echo "status=running" >> "$GITHUB_OUTPUT"
        exit 0
    elif [ "$rc" -eq 0 ] && [ -x "${_out_dir}/chrome" ] && [ -x "${_out_dir}/chromedriver" ]; then
        echo "status=completed" >> "$GITHUB_OUTPUT"
    fi

    exit "$rc"
fi
