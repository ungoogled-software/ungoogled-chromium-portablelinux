#!/bin/bash

CURRENT_DIR=$(dirname $(readlink -f $0))
ROOT_DIR=$(cd ${CURRENT_DIR}/.. && pwd)
GIT_SUBMODULE="ungoogled-chromium"

DEBIAN_VER=${1:-'bullseye-slim'}

IMAGE="ungoogled-chromium-${DEBIAN_VER}:packager"

echo "==============================================================="
echo "  build docker image '${IMAGE}'"
echo "==============================================================="

(cd $ROOT_DIR/docker && docker buildx build -t ${IMAGE} -f ./package.Dockerfile --build-arg DEBIAN_VER=${DEBIAN_VER} .)

[ -n "$(ls -A ${ROOT_DIR}/${GIT_SUBMODULE})" ] || git submodule update --init --recursive

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
