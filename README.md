# ungoogled-chromium-build

Portable Linux build and packaging for [ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium) to be published in the
[ungoogled-chromium-binaries](https://github.com/ungoogled-software/ungoogled-chromium-binaries) web page found [here](https://ungoogled-software.github.io/ungoogled-chromium-binaries/).

The code is mainly adapted from the [ungoogled-chromium-portablelinux](https://github.com/ungoogled-software/ungoogled-chromium-portablelinux) repo (that didn't work for me and seems currently rather unmaintained).

## building
execute `docker-build.sh` script in the root dir. This will
* build a docker image with all needed node, llvm and distro packages to build chromium
* start the docker image, mounts the current dir and runs `build.sh` in it, which executes the actual build process on ungoogled-chromium (mainly: download chromium source tar, unpack and patch it, setup build env and execute ninja build on the result).

>Note that the build takes about 8 hours (on my computer) and consumes about 15G of disk space (you may delete the `target` dir __AFTER PACKAGING__, see [packaging](#packaging))

The script accepts the following params:
1. distro:release (defaults to 'debian:bullseye')
2. major llvm toolchain version (defaults to '16')
3. major node version (defaults to '18')

example: `./docker-build.sh ubuntu:yammy 15 19`

>Note that users of other distros than ubuntu or debian reported compatibility problems when i used ubuntu instead of debian as base image for builds. I therefor recommend to stick to debian base image.

I do not recommend to try to call `build.sh` directly. This will only work if you have a debian or ubuntu installation with all the packages installed and at the same place on your machine as in the docker image. It's the idea behind this build that you do NOT need to manipulate your own linux installation to build ungoogled-chromium.

## packaging
After building, enter the `package` directory and excute `package.sh`. This will create a `tar.xz` and an `AppImage` file in the root dir for your personal use. It takes about 2-3 minutes.</br>
If you want to publish the build result on the [ungoogled-chromium-binaries](https://github.com/ungoogled-software/ungoogled-chromium-binaries) web page you may use the `prepare-publish.sh` script to create commits in your `ungoogled-chromium-binaries` fork for a pull request in the origin [ungoogled-chromium-binaries](https://github.com/ungoogled-software/ungoogled-chromium-binaries) repo. Therefor adjust the paths at the beginning of the script to match the paths to the according repos in your filesystem.
