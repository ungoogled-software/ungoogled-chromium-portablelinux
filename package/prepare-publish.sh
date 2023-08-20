#!/bin/bash

# adjust the paths for your file system
PATH_TO_BUILD_GIT_REPO="$HOME/workspace/clickot/ungoogled-chromium-build"
PATH_TO_PUBLISH_GIT_REPO="$HOME/workspace/clickot/ungoogled-chromium-binaries"

REPO_TAG="$(cd ${PATH_TO_BUILD_GIT_REPO} && git describe --tags --abbrev=0)"
TAG="${REPO_TAG%.1}"

cd ${PATH_TO_PUBLISH_GIT_REPO}
# forced reset to upstream repo
git checkout master && git pull --rebase
git fetch upstream
git reset --hard upstream/master
git push origin master --force

# use conveninence scripts in ungoogled-chromium-binaries repo to produce commits for new binaries
./utilities/submit_github_binary.py --skip-checks --tag ${TAG} --username clickot --output config/platforms/linux_portable/64bit/ ${PATH_TO_BUILD_GIT_REPO}/ungoogled-chromium_${TAG}*.tar.xz 
./utilities/submit_github_binary.py --skip-checks --tag ${TAG} --username clickot --output config/platforms/appimage/64bit/ ${PATH_TO_BUILD_GIT_REPO}/ungoogled-chromium_${TAG}*.AppImage 

