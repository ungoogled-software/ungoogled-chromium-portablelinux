#!/bin/bash

CURRENT_DIR=$(dirname $(readlink -f $0))

ROOT_DIR=$(cd ${CURRENT_DIR}/.. && pwd)
BUILD_DIR="${ROOT_DIR}/build"

chromium_version=$(cat ${ROOT_DIR}/ungoogled-chromium/chromium_version.txt)
ungoogled_revision=$(cat ${ROOT_DIR}/ungoogled-chromium/revision.txt)

FILE_PREFIX=ungoogled-chromium_${chromium_version}-${ungoogled_revision}
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


mkdir ${CURRENT_DIR}/${FILE_PREFIX}_linux
for i in $FILES ; do 
    cp -r ${BUILD_DIR}/src/out/Default/$i ${CURRENT_DIR}/${FILE_PREFIX}_linux
done

(cd ${CURRENT_DIR} && tar cf ${FILE_PREFIX}_linux.tar ${FILE_PREFIX}_linux)

rm -rf ${CURRENT_DIR}/${FILE_PREFIX}_linux && xz "${CURRENT_DIR}/${FILE_PREFIX}_linux.tar" 

set +eux

if [ ! -f "./pkg2appimage" ] ; then
    wget -c $(wget -q https://api.github.com/repos/AppImageCommunity/pkg2appimage/releases -O - | grep "pkg2appimage-.*-x86_64.AppImage" | grep browser_download_url | head -n 1 | cut -d '"' -f 4)
    mv ./pkg2appimage-*.AppImage ./pkg2appimage && chmod +x ./pkg2appimage
fi
./pkg2appimage ./ungoogled-chromium.yaml

mv out/*.AppImage ${ROOT_DIR}/${FILE_PREFIX}.AppImage
mv "${CURRENT_DIR}/${FILE_PREFIX}_linux.tar.xz" ${ROOT_DIR}
rm -rf out ungoogled-chromium

