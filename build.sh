#!/bin/bash

clone=false
while getopts "c" opt; do
    case "${opt}" in
        c) clone=true
        ;;
    esac
done

# directories
# ==================================================
root_dir="$(dirname $(readlink -f $0))"
main_repo="${root_dir}/ungoogled-chromium"

build_dir="${root_dir}/build"
download_cache="${build_dir}/download_cache"
src_dir="${build_dir}/src"

# clean
# ==================================================
echo "cleaning up directories"
rm -rf "${src_dir}" "${build_dir}/domsubcache.tar.gz" 
mkdir -p "${src_dir}" "${download_cache}"

## fetch sources
# ==================================================
if $clone;  then
    "${main_repo}/utils/clone.py" --sysroot amd64 -o "${src_dir}"
else
    "${main_repo}/utils/downloads.py" retrieve -i "${main_repo}/downloads.ini" -c "${download_cache}"
    "${main_repo}/utils/downloads.py" unpack -i "${main_repo}/downloads.ini" -c "${download_cache}" "${src_dir}"
fi
mkdir -p "${src_dir}/out/Default"

# prepare sources
# ==================================================
## apply ungoogled-chromium patches
"${main_repo}/utils/prune_binaries.py" "${src_dir}" "${main_repo}/pruning.list"
"${main_repo}/utils/patches.py" apply "${src_dir}" "${main_repo}/patches"
"${main_repo}/utils/domain_substitution.py" apply -r "${main_repo}/domain_regex.list" -f "${main_repo}/domain_substitution.list" -c "${build_dir}/domsubcache.tar.gz" "${src_dir}"

cd "${src_dir}"

# Use the --oauth2-client-id= and --oauth2-client-secret= switches for
# setting GOOGLE_DEFAULT_CLIENT_ID and GOOGLE_DEFAULT_CLIENT_SECRET at
# runtime -- this allows signing into Chromium without baked-in values
patch -Np1 -i ${root_dir}/use-oauth2-client-switches-as-default.patch
# disable check for a specific node version (here: 22.11.0, but latest lts we use is 22.16.0)
patch -Np1 -i ${root_dir}/drop-nodejs-version-check.patch

# combine local and ungoogled-chromium gn flags
cat "${main_repo}/flags.gn" "${root_dir}/flags.linux.gn" > "${src_dir}/out/Default/args.gn"

# adjust host name to download prebuilt tools below and sysroot files from 
# (see e.g. https://github.com/ungoogled-software/ungoogled-chromium/issues/1846)
sed -i 's/commondatastorage.9oo91eapis.qjz9zk/commondatastorage.googleapis.com/g' ./build/linux/sysroot_scripts/sysroots.json
sed -i 's/commondatastorage.9oo91eapis.qjz9zk/commondatastorage.googleapis.com/g' ./tools/clang/scripts/update.py

## use prebuilt tools for rust and clang insetad of system libs
# use prebuilt rust
./tools/rust/update_rust.py
# to link to rust libraries we need to compile with prebuilt clang
./tools/clang/scripts/update.py
# install sysroot if according gn flag is set to true
if grep -q -F "use_sysroot=true" "${src_dir}/out/Default/args.gn"; then
    ./build/linux/sysroot_scripts/install-sysroot.py --arch=amd64
fi

## Link to system tools required by the build
mkdir -p third_party/node/linux/node-linux-x64/bin && ln -s /usr/bin/node third_party/node/linux/node-linux-x64/bin

### build
# ==================================================
_clang_path="${src_dir}/third_party/llvm-build/Release+Asserts/bin"
## env vars
export CC=$_clang_path/clang
export CXX=$_clang_path/clang++
export AR=$_clang_path/llvm-ar
export NM=$_clang_path/llvm-nm
export LLVM_BIN=${_clang_path}
## flags
llvm_resource_dir=$("$CC" --print-resource-dir)
export CXXFLAGS+=" -resource-dir=${llvm_resource_dir} -B${LLVM_BIN}"
export CPPFLAGS+=" -resource-dir=${llvm_resource_dir} -B${LLVM_BIN}"
export CFLAGS+=" -resource-dir=${llvm_resource_dir} -B${LLVM_BIN}"

# execute build
./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./out/Default/gn gen out/Default --fail-on-unused-args

ninja -C out/Default chrome chrome_sandbox chromedriver
