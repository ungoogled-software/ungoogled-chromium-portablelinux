ARG RELEASE="bookworm"

FROM debian:${RELEASE}

ARG RELEASE
ARG LLVM_VERSION="17"

# set llvm version as env var to make it available for containers building chromium
ENV LLVM_VERSION ${LLVM_VERSION}

# set deb to non-interactive mode and upgrade packages
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && export DEBIAN_FRONTEND=noninteractive 
RUN apt -y update && apt -y upgrade

#  install the needed base packages to add repos
RUN apt -y install lsb-release wget software-properties-common gnupg
# add llvm repo key
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc 
# add repo (has to be done twice for some reason...)
RUN add-apt-repository "deb http://apt.llvm.org/${RELEASE} llvm-toolchain-${RELEASE}-${LLVM_VERSION} main" && add-apt-repository "deb http://apt.llvm.org/${RELEASE} llvm-toolchain-${RELEASE}-${LLVM_VERSION} main"
RUN apt update

# install llvm toolchain
RUN apt -y install clang-${LLVM_VERSION} lldb-${LLVM_VERSION} lld-${LLVM_VERSION} clangd-${LLVM_VERSION}
# install all remaining needed distro packages
RUN apt -y install bison debhelper desktop-file-utils flex gperf gsettings-desktop-schemas-dev imagemagick libasound2-dev libavcodec-dev libavformat-dev libavutil-dev libcap-dev libcups2-dev libcurl4-openssl-dev libdrm-dev libegl1-mesa-dev libelf-dev libevent-dev libexif-dev libflac-dev libgbm-dev libgcrypt20-dev libgl1-mesa-dev libgles2-mesa-dev libglew-dev libglib2.0-dev libglu1-mesa-dev libgtk-3-dev libhunspell-dev libjpeg-dev libjs-jquery-flot libjsoncpp-dev libkrb5-dev liblcms2-dev libminizip-dev libmodpbase64-dev libnspr4-dev libnss3-dev libopenjp2-7-dev libopus-dev libpam0g-dev libpci-dev libpipewire-0.3-dev libpng-dev libpulse-dev libre2-dev libsnappy-dev libspeechd-dev libudev-dev libusb-1.0-0-dev libva-dev libvpx-dev libwebp-dev libx11-xcb-dev libxcb-dri3-dev libxshmfence-dev libxslt1-dev libxss-dev libxt-dev libxtst-dev mesa-common-dev ninja-build nodejs npm pkg-config python3-jinja2 python3-setuptools python3-xcbgen python-is-python3 qtbase5-dev uuid-dev valgrind wdiff x11-apps xcb-proto xfonts-base xvfb xz-utils yasm

# update npm
RUN npm update -g npm

# setup alternatives
RUN <<EOF
update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${LLVM_VERSION} 800
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${LLVM_VERSION} 800
update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-${LLVM_VERSION} 800
update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-${LLVM_VERSION} 800
EOF
# force correct linker versions 'by hand'
RUN <<EOF 
rm -f /usr/bin/lld && ln -s /usr/bin/lld-${LLVM_VERSION} /usr/bin/lld 
rm -f /usr/bin/ld.lld && ln -s /usr/bin/ld.lld-${LLVM_VERSION} /usr/bin/ld.lld 
rm -f /usr/bin/lld-link && ln -s /usr/bin/lld-link-${LLVM_VERSION} /usr/bin/lld-link
EOF
# ensure additional 'share' links for llvm resource dir
RUN <<EOF
_llvm_package_version_="$(apt list llvm-${LLVM_VERSION}-dev | grep -Po "\d+\.\d+\.\d+")" || _llvm_package_version_="${LLVM_VERSION}.0.0"
if [ ! -e /usr/lib/clang/${_llvm_package_version_}/share ] ; then
    (cd /usr/lib/clang/${_llvm_package_version_} && ln -s  ../../llvm-${LLVM_VERSION}/lib/clang/${llvm_package_version}/share)
fi
if [ ! -e /usr/lib/clang/${LLVM_VERSION}/share ] ; then
    (cd /usr/lib/clang/${LLVM_VERSION} && ln -s  ../../llvm-${LLVM_VERSION}/lib/clang/${LLVM_VERSION}/share)
fi
EOF

# create and set workdir to mount in docker build
RUN mkdir /repo
WORKDIR /repo
