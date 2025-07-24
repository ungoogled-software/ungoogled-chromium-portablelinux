#!/bin/bash

clone=false
if [[ "$1" == "-c" ]]; then
    clone=true
fi

# Path variables
_root_dir="$(dirname $(readlink -f $0))"
_main_repo="$_root_dir/ungoogled-chromium"

_build_dir="$_root_dir/build"
_download_cache="$_build_dir/_download_cache"
_src_dir="$_build_dir/src"

rm -rf "$_src_dir/out" || true
mkdir -p "$_src_dir" "$_download_cache"

# Fetch sources
if $clone; then
    "$_main_repo/utils/clone.py" --sysroot amd64 -o "$_src_dir"
else
    "$_main_repo/utils/downloads.py" retrieve -i "$_main_repo/downloads.ini" -c "$_download_cache"
    "$_main_repo/utils/downloads.py" unpack -i "$_main_repo/downloads.ini" -c "$_download_cache" "$_src_dir"
fi

mkdir -p "$_src_dir/out/Default"

# Apply patches and substitutions
"$_main_repo/utils/prune_binaries.py" "$_src_dir" "$_main_repo/pruning.list"
"$_main_repo/utils/patches.py" apply "$_src_dir" "$_main_repo/patches" "$_root_dir/patches"
"$_main_repo/utils/domain_substitution.py" apply -r "$_main_repo/domain_regex.list" -f "$_main_repo/domain_substitution.list" "$_src_dir"

# Set build flags
cat "$_main_repo/flags.gn" "$_root_dir/flags.linux.gn" > "$_src_dir/out/Default/args.gn"

# Fix downloading of prebuilt tools and sysroot files
# (https://github.com/ungoogled-software/ungoogled-chromium/issues/1846)
sed -i "s/commondatastorage.9oo91eapis.qjz9zk/commondatastorage.googleapis.com/g" "$_src_dir/build/linux/sysroot_scripts/sysroots.json"
sed -i "s/commondatastorage.9oo91eapis.qjz9zk/commondatastorage.googleapis.com/g" "$_src_dir/tools/clang/scripts/update.py"

# Use prebuilt tools for rust and clang instead of system libs
"$_src_dir/tools/rust/update_rust.py" && "$_src_dir/tools/clang/scripts/update.py"

# Install sysroot if related GN flag is set to true
if grep -q -F "use_sysroot=true" "$_src_dir/out/Default/args.gn"; then
    "$_src_dir/build/linux/sysroot_scripts/install-sysroot.py" --arch=amd64
fi

# Link system tools required by the build
mkdir -p "$_src_dir/third_party/node/linux/node-linux-x64/bin"
ln -s /usr/bin/node "$_src_dir/third_party/node/linux/node-linux-x64/bin"

_clang_path="$_src_dir/third_party/llvm-build/Release+Asserts/bin"

export CC=$_clang_path/clang
export CXX=$_clang_path/clang++
export AR=$_clang_path/llvm-ar
export NM=$_clang_path/llvm-nm
export LLVM_BIN=$_clang_path

llvm_resource_dir=$("$CC" --print-resource-dir)
export CXXFLAGS+=" -resource-dir=$llvm_resource_dir -B$LLVM_BIN"
export CPPFLAGS+=" -resource-dir=$llvm_resource_dir -B$LLVM_BIN"
export CFLAGS+=" -resource-dir=$llvm_resource_dir -B$LLVM_BIN"

cd "$_src_dir"

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./out/Default/gn gen out/Default --fail-on-unused-args

ninja -C out/Default chrome chrome_sandbox chromedriver
