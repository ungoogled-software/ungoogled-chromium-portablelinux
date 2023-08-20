#!/bin/bash

CURRENT_DIR=$(dirname $(readlink -f $0))

PACKAGE_START=$(date)
echo "==============================================================="
echo "  package tar.xz start at $PACKAGE_START"
echo "==============================================================="

ROOT_DIR=$(cd ${CURRENT_DIR}/.. && pwd)

chromium_version=$(cat ${ROOT_DIR}/ungoogled-chromium/chromium_version.txt)
ungoogled_revision=$(cat ${ROOT_DIR}/ungoogled-chromium/revision.txt)
package_revision=$(cat ${ROOT_DIR}/revision.txt)

FILE_PREFIX=ungoogled-chromium_${chromium_version}-${ungoogled_revision}.${package_revision}
ARCHIVE_OUTPUT="${CURRENT_DIR}/${FILE_PREFIX}_linux.tar.xz"

set -eux

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
libvk_swiftshader.so
libvulkan.so.1
locales/
product_logo_48.png
resources/
resources.pak
v8_context_snapshot.bin
vk_swiftshader_icd.json
xdg-mime
xdg-settings"

mkdir ${CURRENT_DIR}/${FILE_PREFIX}_linux
cp ${CURRENT_DIR}/README ${CURRENT_DIR}/${FILE_PREFIX}_linux
for i in $FILES ; do 
    cp -r ${ROOT_DIR}/target/src/out/Default/$i ${CURRENT_DIR}/${FILE_PREFIX}_linux
done

(cd ${CURRENT_DIR} && tar cf ${FILE_PREFIX}_linux.tar ${FILE_PREFIX}_linux)

rm -rf ${CURRENT_DIR}/${FILE_PREFIX}_linux && xz "${CURRENT_DIR}/${FILE_PREFIX}_linux.tar" 

APPIMAGE_START=$(date)

set +eux

./pkg2appimage ungoogled-chromium.yml

mv out/*.AppImage ${ROOT_DIR}/${FILE_PREFIX}.AppImage
mv "${CURRENT_DIR}/${FILE_PREFIX}_linux.tar.xz" ${ROOT_DIR}
rm -rf out ungoogled-chromium

APPIMAGE_END=$(date)
echo "==============================================================="
echo "  package tar.xz   start at $PACKAGE_START"
echo "  package AppImage start at $APPIMAGE_START"
echo "  package AppImage end   at $APPIMAGE_END"
echo "==============================================================="
