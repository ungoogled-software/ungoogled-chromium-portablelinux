#!/bin/bash

CURRENT_DIR=$(dirname $(readlink -f $0))
ROOT_DIR=$(cd ${CURRENT_DIR}/.. && pwd)
GIT_SUBMODULE="ungoogled-chromium"

IMAGE="ungoogled-chromium-trixie-slim:packager"

(cd $ROOT_DIR/docker && docker buildx build -t ${IMAGE} -f ./package.Dockerfile .)

[ -n "$(ls -A ${ROOT_DIR}/${GIT_SUBMODULE})" ] || git submodule update --init --recursive

cd ${ROOT_DIR} && docker run -it -v ${ROOT_DIR}:/repo ${IMAGE} /bin/bash \
    -c "export APPIMAGE_EXTRACT_AND_RUN=1 && cd package && ./package.sh"
