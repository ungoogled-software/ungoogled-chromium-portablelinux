#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
GIT_SUBMODULE="ungoogled-chromium"

RELEASE=${1:-'bullseye'}
NODE_VERSION=${2:-'18'}

IMAGE="chromium-builder:${RELEASE}"

echo "==============================================================="
echo "  build docker image '${IMAGE}'"
echo "==============================================================="

(cd $BASE_DIR/docker && docker buildx build -t ${IMAGE} -f ./build.Dockerfile --build-arg RELEASE=${RELEASE} --build-arg NODE_VERSION=${NODE_VERSION} .)

[ -n "$(ls -A ${BASE_DIR}/${GIT_SUBMODULE})" ] || git submodule update --init --recursive

BUILD_START=$(date)
echo "==============================================================="
echo "  docker build start at ${BUILD_START}"
echo "==============================================================="

cd ${BASE_DIR} && docker run -it -v ${BASE_DIR}:/repo ${IMAGE} /bin/bash -c "/repo/build.sh"

BUILD_END=$(date)
echo "==============================================================="
echo "  docker build start at ${BUILD_START}"
echo "  docker build end   at ${BUILD_END}"
echo "==============================================================="
