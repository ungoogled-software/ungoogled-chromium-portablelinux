FROM debian:trixie-slim

ARG NODE_VERSION="22"

# set deb to non-interactive mode and upgrade packages
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && export DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update && apt-get -y upgrade

# install latest nodejs lts version
RUN apt-get install -y apt-transport-https ca-certificates curl gnupg &&\
  curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
RUN apt-get -y update && apt-get -y install nodejs && npm update -g npm

# install all needed distro packages
RUN apt-get -y install bison debhelper desktop-file-utils flex gperf gsettings-desktop-schemas-dev imagemagick \
  libasound2-dev libavcodec-dev libavformat-dev libavutil-dev libcap-dev libcups2-dev libcurl4-openssl-dev libdrm-dev \
  libegl1-mesa-dev libelf-dev libevent-dev libexif-dev libflac-dev libgbm-dev libgcrypt20-dev libgl1-mesa-dev libgles2-mesa-dev \
  libglew-dev libglib2.0-dev libglu1-mesa-dev libgtk-3-dev libhunspell-dev libjpeg-dev libjs-jquery-flot libjsoncpp-dev \
  libkrb5-dev liblcms2-dev libminizip-dev libmodpbase64-dev libnspr4-dev libnss3-dev libopenjp2-7-dev libopus-dev libpam0g-dev \
  libpci-dev libpipewire-0.3-dev libpng-dev libpulse-dev libre2-dev libsnappy-dev libspeechd-dev libudev-dev libusb-1.0-0-dev \
  libva-dev libvpx-dev libwebp-dev libx11-xcb-dev libxcb-dri3-dev libxshmfence-dev libxslt1-dev libxss-dev libxt-dev libxtst-dev\
  mesa-common-dev ninja-build pkg-config python3-jinja2 python3-setuptools python3-xcbgen python-is-python3 qtbase5-dev \
  uuid-dev valgrind wdiff x11-apps xcb-proto xfonts-base xvfb xz-utils yasm

# install additional packages needed when cloning the chromium repo (and sudo and vim for convenience)
RUN apt-get -y install git python3-httplib2 python3-pyparsing python3-six rsync sudo vim

# create builder user
RUN groupadd -g 1000 builder && useradd -d /home/builder -g 1000 -u 1000 -m builder

# create workdir to mount in docker build
RUN mkdir /repo

USER builder
WORKDIR /repo
