#!/bin/bash

CURRENT_DIR=$(dirname $(readlink -f $0))
ROOT_DIR=$(cd ${CURRENT_DIR}/.. && pwd)
BUILD_DIR="${ROOT_DIR}/build"
APP_DIR=${CURRENT_DIR}/ungoogled-chromium.AppDir

chromium_version=$(cat ${ROOT_DIR}/ungoogled-chromium/chromium_version.txt)
ungoogled_revision=$(cat ${ROOT_DIR}/ungoogled-chromium/revision.txt)

APP_NAME="ungoogled-chromium"
VERSION="${chromium_version}-${ungoogled_revision}"
ARCH="x86_64"
FILE_PREFIX=$APP_NAME-$VERSION-$ARCH

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

echo "copying release files and create compressed archive ${FILE_PREFIX}_linux.tar.xz"
mkdir -p ${CURRENT_DIR}/${FILE_PREFIX}_linux
for i in $FILES ; do 
    cp -r ${BUILD_DIR}/src/out/Default/$i ${CURRENT_DIR}/${FILE_PREFIX}_linux
done
SIZE="$(du -sk "${FILE_PREFIX}_linux" | cut -f1)"
tar cf - ${FILE_PREFIX}_linux | pv -s"${SIZE}k" | xz > ${FILE_PREFIX}_linux.tar.xz

## create AppImage using appimagetool
rm -rf ${APP_DIR} && mkdir -p ${APP_DIR}/opt/ungoogled-chromium/ ${APP_DIR}/usr/share/icons/hicolor/48x48/apps/
mv ${CURRENT_DIR}/${FILE_PREFIX}_linux/* ${APP_DIR}/opt/ungoogled-chromium/
cp ${CURRENT_DIR}/ungoogled-chromium.desktop ${APP_DIR}
sed -i -e 's|Exec=chromium|Exec=AppRun|g' ${APP_DIR}/ungoogled-chromium.desktop

cat > ${APP_DIR}/AppRun <<'EOF'
#!/bin/sh
THIS="$(readlink -f "${0}")"
HERE="$(dirname "${THIS}")"
export LD_LIBRARY_PATH="${HERE}"/usr/lib:$PATH
export CHROME_WRAPPER="${THIS}"
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
APPIMAGETOOL_APP_NAME=$APP_NAME ARCH=$ARCH VERSION=$VERSION appimagetool -u 'gh-releases-zsync|ungoogled-software|ungoogled-chromium-portablelinux|latest|ungoogled-chromium_*.AppImage.zsync' ${APP_DIR}

#mv "ungoogled-chromium-*-x86_64.AppImage" ${CURRENT_DIR}/${FILE_PREFIX}.AppImage
#mv "ungoogled-chromium-*-x86_64.AppImage.zsync" ${CURRENT_DIR}/${FILE_PREFIX}.AppImage.zsync
rm -rf ${CURRENT_DIR}/${FILE_PREFIX}_linux/ ${APP_DIR}

### mv results to root dir
mv ${CURRENT_DIR}/${FILE_PREFIX}_linux.tar.xz "${ROOT_DIR}"
mv ${CURRENT_DIR}/${FILE_PREFIX}.AppImage* "${ROOT_DIR}"

