#!/bin/bash -eux

# Patches relevant ungoogled-chromium utility scripts to remove GNU-specific command-line arguments

_root_dir=$(dirname $(readlink -f $0))
_patch_dir="$_root_dir/patches/busybox"
_main_repo="$_root_dir/ungoogled-chromium"

echo "Applying patches from $_patch_dir"

for patchfile in "$_patch_dir/prebuild-*.patch"; do
  echo "Applying patch $patchfile"
  patch -p1 -N < $patchfile
done
