# this Dockerfile is an adaption of https://github.com/ungoogled-software/ungoogled-chromium-portablelinux/blob/master/docker-stage1/Dockerfile

ARG DISTRO="debian"
ARG RELEASE="bookworm"

FROM ${DISTRO}:${RELEASE}

ARG DISTRO
ARG RELEASE
ARG LLVM_VERSION="16"
ARG REPO_POSTFIX="-${LLVM_VERSION}"
ARG NODE_VERSION="18"

# set llvm version as env var to make it available for containers building chromium
ENV LLVM_VERSION ${LLVM_VERSION}

# set deb to non-interactive mode and upgrade packages
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && export DEBIAN_FRONTEND=noninteractive \
 && apt-get update && apt-get -y --no-install-recommends upgrade
#  install the needed base packages to add repos
RUN apt-get -y --no-install-recommends install ca-certificates wget lsb-release software-properties-common gnupg2
# add llvm repo
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -\
 && add-apt-repository "deb http://apt.llvm.org/${RELEASE} llvm-toolchain-${RELEASE}${REPO_POSTFIX} main"\
 && wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -\
 && add-apt-repository "deb http://apt.llvm.org/${RELEASE} llvm-toolchain-${RELEASE}${REPO_POSTFIX} main"
 
RUN apt-get update

# install llvm toolchain
RUN apt-get -y install --no-install-recommends clang-${LLVM_VERSION} clang-${LLVM_VERSION}-doc clangd-${LLVM_VERSION} clang-format-${LLVM_VERSION} clang-tools-${LLVM_VERSION}\
 libc++-${LLVM_VERSION}-dev libc++abi-${LLVM_VERSION}-dev libclang-${LLVM_VERSION}-dev libclang-rt-${LLVM_VERSION}-dev libfuzzer-${LLVM_VERSION}-dev\
 libllvm-${LLVM_VERSION}-ocaml-dev libomp-${LLVM_VERSION}-dev lld-${LLVM_VERSION} lldb-${LLVM_VERSION} llvm-${LLVM_VERSION}-doc llvm-${LLVM_VERSION}-examples
# install all remaining needed distro packages
RUN apt-get -y install --no-install-recommends bison debhelper desktop-file-utils flex fonts-ipafont-gothic fonts-ipafont-mincho gperf gsettings-desktop-schemas-dev\
 imagemagick libasound2-dev libavcodec-dev libavformat-dev libavutil-dev libcap-dev libcups2-dev libcurl4-openssl-dev libdrm-dev libegl1-mesa-dev libelf-dev libevent-dev\
 libexif-dev libflac-dev libgbm-dev libgcrypt20-dev libgl1-mesa-dev libgles2-mesa-dev libglew-dev libglib2.0-dev libglu1-mesa-dev libgtk-3-dev libhunspell-dev libjpeg-dev\
 libjs-jquery-flot libjsoncpp-dev libkrb5-dev liblcms2-dev libminizip-dev libmodpbase64-dev libnspr4-dev libnss3-dev libopenjp2-7-dev libopus-dev libpam0g-dev libpci-dev\
 libpipewire-0.3-dev libpng-dev libpulse-dev libre2-dev libsnappy-dev libspeechd-dev libudev-dev libusb-1.0-0-dev libva-dev libvpx-dev libwebp-dev libx11-xcb-dev\
 libxcb-dri3-dev libxshmfence-dev libxslt1-dev libxss-dev libxt-dev libxtst-dev mesa-common-dev ninja-build nodejs npm pkg-config python3-jinja2 python3-xcbgen\
 python-is-python3 python3-setuptools qtbase5-dev uuid-dev valgrind wdiff x11-apps xcb-proto xfonts-base xvfb xz-utils yasm
# update npm
RUN npm update -g npm

# setup alternatives
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${LLVM_VERSION} 800\
 && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${LLVM_VERSION} 800\
 && update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-${LLVM_VERSION} 800\
 && update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-${LLVM_VERSION} 800
# ensure correct linker versions 'by hand'
RUN rm -f /usr/bin/lld && ln -s /usr/bin/lld-${LLVM_VERSION} /usr/bin/lld \
 && rm -f /usr/bin/ld.lld && ln -s /usr/bin/ld.lld-${LLVM_VERSION} /usr/bin/ld.lld \
 && rm -f /usr/bin/lld-link && ln -s /usr/bin/lld-link-${LLVM_VERSION} /usr/bin/lld-link
# setup additional links for llvm resource dir
RUN llvm_package_version="$(apt list llvm-${LLVM_VERSION}-dev | grep -Po "\d+\.\d+\.\d+")" || llvm_package_version="${LLVM_VERSION}.0.0"\
 && if [ -d "/usr/lib/llvm-${LLVM_VERSION}/lib/clang/${LLVM_VERSION}/share" ]; then (cd /usr/lib/clang/${LLVM_VERSION} && ln -s  ../../llvm-${LLVM_VERSION}/lib/clang/${LLVM_VERSION}/share);\
    else (cd /usr/lib/clang/${llvm_package_version} && ln -s  ../../llvm-${LLVM_VERSION}/lib/clang/${llvm_package_version}/share); fi

# create and set workdir to mount in docker build
RUN mkdir /repo
WORKDIR /repo
