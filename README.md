# ungoogled-chromium-portablelinux
Portable Linux build and packaging for [ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium) to be published in the
[ungoogled-chromium-binaries](https://github.com/ungoogled-software/ungoogled-chromium-binaries) web page found [here](https://ungoogled-software.github.io/ungoogled-chromium-binaries/).
>Note that the builds are executed on an debian:bullseye docker image again, so the release's binaries work again on e.g. ubuntu 20.04 and maybe other 'older' systems :)

## building
execute `docker-build.sh` script in the root dir. This will
* build a debian-based docker image with all needed llvm, nodejs and distro packages to build chromium
* start the docker image, mounts the current dir and runs `build.sh` in it, which executes the actual build process on ungoogled-chromium (mainly: download chromium source tar, unpack 
  and patch it, setup build env and execute ninja build on the result).
* if you want to checkout chromium instead of downloading a tarball (e.g. because there's no tarball available yet), call `docker-build.sh -c`. 
  Instead of tarball downloading this will call the `<ungoogled-chromium>/utils/clone.py` script for cloning the source tree of chromium and all needed submodules etc.

>Note that the build takes several hours (about 8 hous on my computer) and consumes about 15G of disk space (you may delete the `build` dir __AFTER PACKAGING__, see [packaging](#packaging))

The script has a switch -c wether to fetch a chromium tarball (defualt) or to clone the chromium code (-c): `./docker-build.sh -c`.
This is useful when for some reasons the tarball is not (yet) available.

I do not recommend to call `build.sh` directly. This will only work if you have a debian or ubuntu installation with all the packages installed and at the same place in the filesystem on your machine as in the docker image. It's the idea behind this docker-based build that you do NOT need to manipulate your own linux installation to build ungoogled-chromium.

## packaging
After building, enter the `package` directory and excute `package.sh`. Alternatively, you may execute `docker-package.sh`, building a docker image similar to `docker-build.sh`.
These will create a `tar.xz` and an `AppImage` file in the root dir for your personal use. It takes about 2-3 minutes.</br>
