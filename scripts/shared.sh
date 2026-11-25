#!/bin/bash
set -euo pipefail

# shared build functions used by local and CI scripts

export PATH="${RUSTUP_HOME}/bin:$PATH"

# resolve repo root directory regardless of caller location
repo_root() {
	local _base_dir
	_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
	cd "${_base_dir}/.." >/dev/null 2>&1 && pwd
}

setup_arch() {
	_host_arch=$(uname -m)

	if [ "$_host_arch" = "x86_64" ]; then
		_host_arch="x64"
	elif [ "$_host_arch" = "aarch64" ]; then
		_host_arch="arm64"
	fi

	_build_arch="$_host_arch"
	if [ -n "${ARCH:-}" ]; then
		_build_arch="$ARCH"
	fi

	if [ "$_build_arch" = "x86_64" ]; then
		_build_arch=x64
	fi
}

setup_paths() {
	_root="$(repo_root)"
	_main_repo="${_root}/ungoogled-chromium"
	_build_dir="${_root}/build"
	_dl_cache="${_build_dir}/download_cache"
	_src_dir="${_build_dir}/src"
	_out_dir="${_src_dir}/out/Default"
	setup_arch

	mkdir -p "${_dl_cache}"
}

fetch_sources() {
	local use_clone="${1:-false}"
	local use_gentoo_source_tar="${2:-false}"
	local crubit_rev="${3:-d757594f6f7ac27c0cf9c8ea63d9136f8e1f77ae}"

	local stamp="${_src_dir}/.downloaded.stamp"
	if [ -f "${stamp}" ]; then
		echo "Sources already present, skipping download/unpack"
		return 0
	fi

	if ${use_clone}; then
		_host_arch_clone="$_build_arch"
		if [ "$_host_arch_clone" = x64 ]; then
			_host_arch_clone="amd64"
		fi

		"${_main_repo}/utils/clone.py" --sysroot "$_host_arch_clone" -o "${_src_dir}"
	else
		if ${use_gentoo_source_tar}; then
			# replace url and filename to switch to gentoo's chromium source tar
			sed -i 's|https://commondatastorage.googleapis.com/chromium-browser-official|https://github.com/chromium-linux-tarballs/chromium-tarballs/releases/download/%(_chromium_version)s|g' "${_main_repo}/downloads.ini"
			sed -i 's|chromium-%(_chromium_version)s-lite.tar.xz|chromium-%(_chromium_version)s-linux.tar.xz|g' "${_main_repo}/downloads.ini"
		fi
		"${_main_repo}/utils/downloads.py" retrieve -i "${_main_repo}/downloads.ini" -c "${_dl_cache}"
		"${_main_repo}/utils/downloads.py" unpack -i "${_main_repo}/downloads.ini" -c "${_dl_cache}" "${_src_dir}"
	fi

    # fetch crubit with specified commit (legacy way since git version on debian is older than 2.49)
	git clone https://chromium.googlesource.com/external/github.com/google/crubit.git ${_src_dir}/crubit
	( cd ${_src_dir}/crubit && git checkout $crubit_rev && rm rust-toolchain.toml )
	
	touch "${stamp}"
}

apply_patches() {
	if [ ! -f "${_src_dir}/.patched.stamp" ]; then
		"${_main_repo}/utils/prune_binaries.py" "${_src_dir}" "${_main_repo}/pruning.list"
		"${_main_repo}/utils/patches.py" apply "${_src_dir}" "${_main_repo}/patches" "${_root}/patches"
		touch "${_src_dir}/.patched.stamp"
	fi
}

apply_domsub() {
	if [ ! -f "${_src_dir}/.domsub.stamp" ]; then
		"${_main_repo}/utils/domain_substitution.py" apply -r "${_main_repo}/domain_regex.list" -f "${_main_repo}/domain_substitution.list" "${_src_dir}"
		touch "${_src_dir}/.domsub.stamp"
	fi
}

write_gn_args() {
	mkdir -p "${_out_dir}"

	cat "${_main_repo}/flags.gn" "${_root}/flags.linux.gn" | tee "${_out_dir}/args.gn"
	
	echo "rust_sysroot_absolute=\"${RUSTUP_HOME}/toolchains/stable-$(rustc --print host-tuple)/\"" | tee -a "${_out_dir}/args.gn"
	echo "rustc_version=\"$(rustc --version | awk '{ print $2 ;}')\"" | tee -a "${_out_dir}/args.gn"
	
	echo "target_cpu = \"$_build_arch\"" | tee -a "${_out_dir}/args.gn"
	echo "v8_target_cpu = \"$_build_arch\"" | tee -a "${_out_dir}/args.gn"
}

# fix downloading of prebuilt tools and sysroot files
# (https://github.com/ungoogled-software/ungoogled-chromium/issues/1846)
fix_tool_downloading() {
	sed -i 's/commondatastorage.9oo91eapis.qjz9zk/commondatastorage.googleapis.com/g' \
		"${_src_dir}/build/linux/sysroot_scripts/sysroots.json" \
		"${_src_dir}/tools/clang/scripts/update.py" \
		"${_src_dir}/tools/clang/scripts/build.py"

	sed -i 's/chromium.9oo91esource.qjz9zk/chromium.googlesource.com/g' \
		"${_src_dir}/tools/clang/scripts/build.py" \
		"${_src_dir}/tools/rust/build_rust.py" \
		"${_src_dir}/tools/rust/build_bindgen.py"

	sed -i 's/chrome-infra-packages.8pp2p8t.qjz9zk/chrome-infra-packages.appspot.com/g' \
		"${_src_dir}/tools/rust/build_rust.py"
}

setup_toolchain() {
	# Chromium currently has no non-x86 llvm/rust builds on
	# Linux, so we have to build it ourselves.
	if [ "$_host_arch" = x64 ]; then
		"${_src_dir}/tools/rust/update_rust.py"
		"${_src_dir}/tools/clang/scripts/update.py"
	else
		"${_src_dir}/tools/clang/scripts/build.py" \
			--without-fuchsia --without-android --disable-asserts \
			--host-cc=clang --host-cxx=clang++ --use-system-cmake \
			--with-ml-inliner-model=

		export CARGO_HOME="${_src_dir}/third_party/rust-src/cargo-home"
		"${_src_dir}/tools/rust/build_rust.py" \
			--skip-test

		"${_src_dir}/tools/rust/build_bindgen.py"
	fi

	if grep -q -F "use_sysroot=true" "${_out_dir}/args.gn"; then
		"${_src_dir}/build/linux/sysroot_scripts/install-sysroot.py" --arch="$_host_arch" &
		if [ "$_build_arch" != "$_host_arch" ]; then
			"${_src_dir}/build/linux/sysroot_scripts/install-sysroot.py" --arch="$_build_arch" &
		fi
		wait
	fi

	mkdir -p "${_src_dir}/third_party/node/linux/node-linux-x64/bin"
	ln -sf "$(which node)" "${_src_dir}/third_party/node/linux/node-linux-x64/bin/node"
	mkdir -p "${_src_dir}/third_party/gperf/cipd/bin/"
	ln -sf "$(which gperf)" "${_src_dir}/third_party/gperf/cipd/bin/gperf"
	mkdir -p "${_src_dir}/third_party/dawn/tools/golang/linux-amd64/bin"
	ln -sf "$(which go)" "${_src_dir}/third_party/dawn/tools/golang/linux-amd64/bin/go"
	mkdir -p "${_src_dir}/buildtools/linux64-format"
	ln -sf "$(which clang-format)" "${_src_dir}/buildtools/linux64-format/clang-format"
	rm -rf "${_src_dir}/third_party/devtools-frontend/src/node_modules/esbuild/"
	ln -s /usr/lib/node_modules/esbuild/ "${_src_dir}/third_party/devtools-frontend/src/node_modules/esbuild"
	mkdir -p "${_src_dir}/third_party/typescript/linux-amd64/src/lib"
	ln -sf "$(which tsc)" "${_src_dir}/third_party/typescript/linux-amd64/src/lib/tsc"
    mkdir -p ${_src_dir}/third_party/rust-toolchain/crubit/lib/third_party/
	ln -s ${_src_dir}/crubit ${_src_dir}/third_party/rust-toolchain/crubit/lib/third_party/crubit
	
	local clang_bin="${_src_dir}/third_party/llvm-build/Release+Asserts/bin"
	export CC="${clang_bin}/clang"
	export CXX="${clang_bin}/clang++"
	export AR="${clang_bin}/llvm-ar"
	export NM="${clang_bin}/llvm-nm"
	export LLVM_BIN="${clang_bin}"

	local resource_dir="$(${CC%% *} --print-resource-dir)"
	export CXXFLAGS+=" -resource-dir=${resource_dir} -B${LLVM_BIN}"
	export CPPFLAGS+=" -resource-dir=${resource_dir} -B${LLVM_BIN}"
	export CFLAGS+=" -resource-dir=${resource_dir} -B${LLVM_BIN}"

    # build crubit
	(
		cd ${_src_dir}/third_party/rust-toolchain/crubit/lib/third_party/crubit
		#_rustc_libs="${RUSTUP_HOME}/toolchains/$(rustc --print host-tuple)/lib"
		_rustc_libs="${RUSTUP_HOME}/toolchains/stable-$(rustc --print host-tuple)/lib/rustlib/$(rustc --print host-tuple)/lib"
		export CARGO_TARGET_DIR=target
		export RUSTC_BOOTSTRAP=1
		export RUSTFLAGS+=" -Clink-args=-Wl,-z,origin -Clink-args=-Wl,-rpath,$_rustc_libs"
		cargo build --locked --release -p cc_bindings_from_rs --bin cc_bindings_from_rs
		install -Dm755 -t ${_src_dir}/third_party/rust-toolchain/crubit/bin/ target/release/cc_bindings_from_rs
	)
}

gn_gen() {
	cd "${_src_dir}"
	./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
	./out/Default/gn gen out/Default --fail-on-unused-args
}

maybe_build() {
	# Allow the use of nightly features with stable Rust compiler
    # https://github.com/ungoogled-software/ungoogled-chromium/pull/2696#issuecomment-1918173198
    export RUSTC_BOOTSTRAP=1
    # to avoid error because of missing librustc_driver*.so
	export RUSTFLAGS+=' -Clink-args=-Wl,-z,origin -Clink-args=-Wl,-rpath,$ORIGIN/../lib'

	cd "${_src_dir}"

	ninja -C out/Default chrome chromedriver
}
