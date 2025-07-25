#!/bin/bash

CURRENT_DIR=$(dirname $(readlink -f $0))
ROOT_DIR=$(cd ${CURRENT_DIR}/.. && pwd)
GIT_SUBMODULE="ungoogled-chromium"

IMAGE="ungoogled-chromium-trixie-slim:packager"

echo "==============================================================="
echo "  build docker image '${IMAGE}'"
echo "==============================================================="

(cd $ROOT_DIR/docker && docker buildx build -t ${IMAGE} -f ./package.Dockerfile --build-arg DEBIAN_VER=${DEBIAN_VER} .)

[ -n "$(ls -A ${ROOT_DIR}/${GIT_SUBMODULE})" ] || git submodule update --init --recursive

# Since AppImages inside Docker require fuze, we will instead extract and run it
sed -i '54 s/\.\/pkg2appimage \.\/ungoogled-chromium.yaml/\.\/pkg2appimage --appimage-extract-and-run \.\/ungoogled-chromium.yaml/' ${CURRENT_DIR}/package.sh

PACKAGE_START=$(date)
echo "==============================================================="
echo "  docker package start at ${BUILD_START}"
echo "==============================================================="

cd ${ROOT_DIR} && docker run -it -v ${ROOT_DIR}:/repo ${IMAGE} /bin/bash -c "cd package && ./package.sh"

PACKAGE_END=$(date)
echo "==============================================================="
echo "  docker package start at ${PACKAGE_START}"
echo "  docker package end   at ${PACKAGE_END}"
echo "==============================================================="

# Revert package script
sed -i '54 s/\.\/pkg2appimage --appimage-extract-and-run \.\/ungoogled-chromium.yaml/\.\/pkg2appimage \.\/ungoogled-chromium.yaml/' ${CURRENT_DIR}/package.sh
