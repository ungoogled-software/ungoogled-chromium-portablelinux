set -ex

docker build --rm -f "Dockerfile-stage3" -t ug-chromium-builder-stage3:latest ./

docker run --privileged -ti -v `pwd`:/data ug-chromium-builder-stage3:latest bash -c "./package.appimage.sh.ungoogin"

