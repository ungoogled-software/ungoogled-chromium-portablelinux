FROM debian:trixie-slim

## Set deb to non-interactive mode and upgrade packages
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && export DEBIAN_FRONTEND=noninteractive
RUN apt -y update && apt -y upgrade

## Install system dependencies
RUN apt -y install binutils desktop-file-utils dpkg file imagemagick wget xz-utils pv curl jq

## Create and set WORKDIR to mount in docker build
WORKDIR /repo
