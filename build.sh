#!/bin/bash -eux

# Simple build script for Portable Linux
# NOTE: This script will delete all build intermediates every time it runs. Proceed with caution.

_root_dir=$(dirname $(readlink -f $0))
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

rm -rf "$_src_dir" || true
rm -f "$_root_dir/build/domsubcache.tar.gz" || true
mkdir -p "$_src_dir/out/Default"
mkdir -p "$_download_cache"

./check_patch_type.sh

"$_main_repo/utils/downloads.py" retrieve -i "$_main_repo/downloads.ini" -c "$_download_cache"
"$_main_repo/utils/downloads.py" unpack -i "$_main_repo/downloads.ini" -c "$_download_cache" "$_src_dir"
"$_main_repo/utils/prune_binaries.py" "$_src_dir" "$_main_repo/pruning.list"
"$_main_repo/utils/patches.py" apply "$_src_dir" "$_main_repo/patches" "$_root_dir/patches"
"$_main_repo/utils/domain_substitution.py" apply -r "$_main_repo/domain_regex.list" -f "$_main_repo/domain_substitution.list" -c "$_root_dir/build/domsubcache.tar.gz" "$_src_dir"
cp "$_main_repo/flags.gn" "$_src_dir/out/Default/args.gn"
cat "$_root_dir/flags.portable.gn" >> "$_src_dir/out/Default/args.gn"

# Set commands or paths to LLVM-provided tools outside the script via 'export ...'
# or before these lines
export AR=${AR:=llvm-ar}
export NM=${NM:=llvm-nm}
export CC=${CC:=clang}
export CXX=${CXX:=clang++}
# You may also set CFLAGS, CPPFLAGS, CXXFLAGS, and LDFLAGS
# See build/toolchain/linux/unbundle/ in the Chromium source for more details.
#
# Hack to allow clang to find the default cfi_blacklist.txt
export CXXFLAGS+=-resource-dir=$("$CC" --print-resource-dir) \

export CPPFLAGS+=-resource-dir=$("$CC" --print-resource-dir) \

export CFLAGS+=-resource-dir=$("$CC" --print-resource-dir) \


cd "$_src_dir"

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./out/Default/gn gen out/Default --fail-on-unused-args
ninja -C out/Default chrome chrome_sandbox chromedriver
