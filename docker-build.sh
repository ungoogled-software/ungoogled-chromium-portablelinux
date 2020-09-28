set -ex

git submodule update --init --recursive

mkdir -p build

NCPUS=""
if [ "$LIMIT_CORES" -ge 1 ]; then
    NCPUS="--cpus $LIMIT_CORES"
fi

EXTRACMD="${EXTRACMD:-true}"
FLAGS="$(echo "$ADD_FLAGS" | sed -Ee 's|\s+|\n|g')"
echo -e "${FLAGS}" > build/flags.local.gn

# Build first stage docker
pushd docker-stage1
docker build --rm -f "Dockerfile" -t ug-chromium-builder-stage1:latest ./
popd

# Build second stage docker
docker build --rm -f "Dockerfile-stage2" -t ug-chromium-builder-stage2:latest ./

# start the browser build
docker run $NCPUS -ti -v `pwd`/build:/repo/build ug-chromium-builder-stage2:latest bash -c "$EXTRACMD && ./build.sh && ./package.sh"

