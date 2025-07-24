# Usage(on repo root folder):
#   docker build . -t ungoogled-chromium:packager -f ./docker/package.Dockerfile
# Optionally, add arguments like: --build-arg DEBIAN_VER=latest

# Arguments configuration
ARG DEBIAN_VER="bullseye-slim"

# Environment setup
FROM debian:${DEBIAN_VER}

## Set deb to non-interactive mode and upgrade packages
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && export DEBIAN_FRONTEND=noninteractive
RUN apt -y update && apt -y upgrade

## Install system dependencies
RUN apt -y install binutils desktop-file-utils dpkg file imagemagick wget xz-utils

## Create and set WORKDIR to mount in docker build
RUN mkdir /repo
WORKDIR /repo
