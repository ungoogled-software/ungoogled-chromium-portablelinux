#!/bin/bash


BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
GIT_REPO="ungoogled-chromium"

DISTRO_RELEASE=${1:-'debian:bookworm'}
LLVM_VERSION=${2:-'16'}
NODE_VERSION=${3:-'18'}

DISTRO=$(echo ${DISTRO_RELEASE}| cut -d':' -f1)
RELEASE=$(echo ${DISTRO_RELEASE}| cut -d':' -f2)
[ "$LLVM_VERSION" -gt "16" ] || REPO_POSTFIX="-$LLVM_VERSION"

IMAGE="chromium-builder-${RELEASE}:llvm-${LLVM_VERSION}"

cd $BASE_DIR 

echo "docker buildx build -t ${IMAGE} --build-arg DISTRO=${DISTRO} --build-arg RELEASE=${RELEASE} --build-arg LLVM_VERSION=${LLVM_VERSION} --build-arg REPO_POSTFIX=${REPO_POSTFIX} --build-arg NODE_VERSION=${NODE_VERSION} ."
(cd $BASE_DIR/docker && docker buildx build -t ${IMAGE} --build-arg DISTRO=${DISTRO} --build-arg RELEASE=${RELEASE} --build-arg LLVM_VERSION=${LLVM_VERSION} --build-arg REPO_POSTFIX=${REPO_POSTFIX} --build-arg NODE_VERSION=${NODE_VERSION} . )

[ -n "$(ls -A ungoogled-chromium)" ] || git submodule update --init --recursive

BUILD_START=$(date)
echo "==============================================================="
echo "  docker build start at ${BUILD_START}"
echo "==============================================================="

cd ${BASE_DIR}

docker run -it -v ${BASE_DIR}:/repo ${IMAGE} /bin/bash -c "/repo/build.sh"

BUILD_END=$(date)
echo "==============================================================="
echo "  docker build start at ${BUILD_START}"
echo "  docker build end   at ${BUILD_END}"
echo "==============================================================="

