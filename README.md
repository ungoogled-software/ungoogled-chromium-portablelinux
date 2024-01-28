# ungoogled-chromium-portablelinux
Portable Linux build and packaging for [ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium) to be published in the
[ungoogled-chromium-binaries](https://github.com/ungoogled-software/ungoogled-chromium-binaries) web page found [here](https://ungoogled-software.github.io/ungoogled-chromium-binaries/).
>Note that the builds are executed on an debian:bullseye docker image again, so the release's binaries work again on e.g. ubuntu 20.04 and maybe other 'older' systems :)

## building
execute `docker-build.sh` script in the root dir. This will
* build a debian-based docker image with all needed llvm, nodejs and distro packages to build chromium
* start the docker image, mounts the current dir and runs `build.sh` in it, which executes the actual build process on ungoogled-chromium (mainly: download chromium source tar, unpack and patch it, setup build env and execute ninja build on the result).

>Note that the build takes about 9 hours (on my computer) and consumes about 15G of disk space (you may delete the `build` dir __AFTER PACKAGING__, see [packaging](#packaging))

The script accepts the following params:
1. debian release (defaults to 'bullseye')
2. node version (defaults to '18')

example: `./docker-build.sh bookworm 17`

>Note that currently (starting from 120.xx) the `sysroot` feature with debian:bullseye is used to reach same compatibility as chromium itself. So it might be you face errors when executing chromium if you use other values than the defaults.

I do not recommend to call `build.sh` directly. This will only work if you have a debian or ubuntu installation with all the packages installed and at the same place in the filesystem on your machine as in the docker image. It's the idea behind this docker-based build that you do NOT need to manipulate your own linux installation to build ungoogled-chromium.

## packaging
After building, enter the `package` directory and excute `package.sh`. Alternatively, you may execute `docker-package.sh`, building a docker image similar to `docker-build.sh`.
These will create a `tar.xz` and an `AppImage` file in the root dir for your personal use. It takes about 2-3 minutes.</br>
