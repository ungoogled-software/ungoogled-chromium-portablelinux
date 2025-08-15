#!/bin/bash
set -euo pipefail

_current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
_root_dir="$(cd "${_current_dir}/.." && pwd)"
_build_dir="${_root_dir}/build"
_app_dir="${_current_dir}/ungoogled-chromium.AppDir"

_chromium_version=$(cat "${_root_dir}/ungoogled-chromium/chromium_version.txt")
_ungoogled_revision=$(cat "${_root_dir}/ungoogled-chromium/revision.txt")

_app_name="ungoogled-chromium"
_version="${_chromium_version}-${_ungoogled_revision}"
_arch="x86_64"
_file_prefix=${_app_name}-${_version}-${_arch}

_files="chrome
chrome_100_percent.pak
chrome_200_percent.pak
chrome_crashpad_handler
chromedriver
chrome_sandbox
chrome-wrapper
icudtl.dat
libEGL.so
libGLESv2.so
libqt5_shim.so
libqt6_shim.so
libvk_swiftshader.so
libvulkan.so.1
locales/
product_logo_48.png
resources.pak
v8_context_snapshot.bin
vk_swiftshader_icd.json
xdg-mime
xdg-settings"

echo "copying release files and creating ${_file_prefix}_linux.tar.xz"

mkdir -p "${_current_dir}/${_file_prefix}_linux"

for i in $_files ; do
    cp -r "${_build_dir}/src/out/Default/$i" "${_current_dir}/${_file_prefix}_linux"
done

_size="$(du -sk "${_file_prefix}_linux" | cut -f1)"
tar cf - "${_file_prefix}_linux" | pv -s"${_size}k" | xz > "${_file_prefix}_linux.tar.xz"

# create AppImage
rm -rf "${_app_dir}"
mkdir -p "${_app_dir}/opt/ungoogled-chromium/" "${_app_dir}/usr/share/icons/hicolor/48x48/apps/"
mv "${_current_dir}/${_file_prefix}_linux"/* "${_app_dir}/opt/ungoogled-chromium/"
cp "${_current_dir}/../package/ungoogled-chromium.desktop" "${_app_dir}"
sed -i -e 's|Exec=chromium|Exec=AppRun|g' "${_app_dir}/ungoogled-chromium.desktop"

cat > "${_app_dir}/AppRun" <<'EOF'
#!/bin/sh
THIS="$(readlink -f "${0}")"
HERE="$(dirname "${THIS}")"
export LD_LIBRARY_PATH="${HERE}"/usr/lib:$PATH
export CHROME_WRAPPER="${THIS}"
"${HERE}"/opt/ungoogled-chromium/chrome "$@"
EOF
chmod a+x "${_app_dir}/AppRun"

cp "${_app_dir}/opt/ungoogled-chromium/product_logo_48.png" "${_app_dir}/usr/share/icons/hicolor/48x48/apps/chromium.png"
cp "${_app_dir}/usr/share/icons/hicolor/48x48/apps/chromium.png" "${_app_dir}"

APPIMAGETOOL_APP_NAME=${_app_name} ARCH=${_arch} VERSION=${_version} appimagetool -u \
    'gh-releases-zsync|ungoogled-software|ungoogled-chromium-portablelinux|latest|ungoogled-chromium-*.AppImage.zsync' \
    "${_app_dir}"

rm -rf "${_current_dir}/${_file_prefix}_linux/" "${_app_dir}"

mv "${_current_dir}/${_file_prefix}_linux.tar.xz" "${_build_dir}"
mv "${_current_dir}/${_file_prefix}.AppImage"* "${_build_dir}"
