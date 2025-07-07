#!/bin/bash

CURRENT_DIR=$(dirname $(readlink -f $0))
ROOT_DIR=$(cd ${CURRENT_DIR}/.. && pwd)
BUILD_DIR="${ROOT_DIR}/build"
APP_DIR=${CURRENT_DIR}/ungoogled-chromium.AppDir

chromium_version=$(cat ${ROOT_DIR}/ungoogled-chromium/chromium_version.txt)
ungoogled_revision=$(cat ${ROOT_DIR}/ungoogled-chromium/revision.txt)
FILE_PREFIX=ungoogled-chromium_${chromium_version}-${ungoogled_revision}


### create tar.xz package
FILES="chrome
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

mkdir -p ${CURRENT_DIR}/${FILE_PREFIX}_linux
set -x
for i in $FILES ; do 
    cp -r ${BUILD_DIR}/src/out/Default/$i ${CURRENT_DIR}/${FILE_PREFIX}_linux
done

(cd ${CURRENT_DIR} && tar cf ${FILE_PREFIX}_linux.tar ${FILE_PREFIX}_linux)

rm -rf ${CURRENT_DIR}/${FILE_PREFIX}_linux ${CURRENT_DIR}/${FILE_PREFIX}_linux.tar.xz
xz ${CURRENT_DIR}/${FILE_PREFIX}_linux.tar 
set +x

### create AppImage using appimagetool
rm -rf ${APP_DIR} && mkdir -p ${APP_DIR}/opt/ungoogled-chromium/ ${APP_DIR}/usr/share/icons/hicolor/48x48/apps/
tar xf ${CURRENT_DIR}/ungoogled-chromium_*_linux.tar.xz --strip-components=1 -C ${APP_DIR}/opt/ungoogled-chromium/
cp ${CURRENT_DIR}/ungoogled-chromium.desktop ${APP_DIR}
sed -i -e 's|Exec=chromium|Exec=AppRun|g' ${APP_DIR}/ungoogled-chromium.desktop

cat > ${APP_DIR}/AppRun <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}"/usr/lib:$PATH
"${HERE}"/opt/ungoogled-chromium/chrome "$@"
EOF
chmod a+x ${APP_DIR}/AppRun

cp ${APP_DIR}/opt/ungoogled-chromium/product_logo_48.png ${APP_DIR}/usr/share/icons/hicolor/48x48/apps/chromium.png
cp ${APP_DIR}/usr/share/icons/hicolor/48x48/apps/chromium.png ${APP_DIR}
# download appimagetool if not in PATH or locally present
if ! command -v appimagetool >/dev/null; then
    if [ ! -f ./appimagetool ] ; then
        URL=$(curl -s https://api.github.com/repos/AppImage/appimagetool/releases/latest | jq '.assets[].browser_download_url' | grep x86_64 | sed 's/"//g')
        wget -q --show-progress -O appimagetool $URL && chmod +x appimagetool
    fi
    export PATH=".:$PATH"
fi
appimagetool -u 'gh-releases-zsync|ungoogled-software|ungoogled-chromium-portablelinux|latest|ungoogled-chromium_*.AppImage.zsync' ${APP_DIR}

mv "Chromium_(ungoogled)-x86_64.AppImage" ${CURRENT_DIR}/${FILE_PREFIX}.AppImage
mv "Chromium_(ungoogled)-x86_64.AppImage.zsync" ${CURRENT_DIR}/${FILE_PREFIX}.AppImage.zsync
rm -rf ${APP_DIR}


### mv results to root dir
mv ${CURRENT_DIR}/${FILE_PREFIX}_linux.tar.xz "${ROOT_DIR}"
mv ${CURRENT_DIR}/${FILE_PREFIX}.AppImage* "${ROOT_DIR}"

