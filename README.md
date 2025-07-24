# ungoogled-chromium-portablelinux
Portable Linux (`.AppImage`) packaging for [ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium).

## Downloads
- [Download binaries from GitHub Releases](https://github.com/ungoogled-software/ungoogled-chromium-portablelinux/releases).
- [Download binaries from the Contributor Binaries website](https://ungoogled-software.github.io/ungoogled-chromium-binaries/).

## Building
To build the binary, run `docker-build.sh` script in the root dir.

The `docker-build.sh` script will:
1. Create a Docker image of a Debian-based building environment with all required packages (llvm, nodejs and distro packages) included.
2. Run `build.sh` in the created Docker image to build ungoogled-chromium.

Running `build.sh` directly will not work unless you're running a Debian-based distro and have all necessary dependencies installed. This repo is designed to avoid having to configure the building environment on your Linux installation.

### Packaging
After building, go to the `package` directory and run `package.sh`. Alternatively, you can run `docker-package.sh`, and a docker image will be created & used instead, similar to `docker-build.sh`.

Either of these scripts will create `tar.xz` and `AppImage` files in the root dir.

### Development
By default, the build script uses tarball. If you need to use a source tree clone, you can run `docker-build.sh -c` instead. This may be useful if tarball for a release isn't available yet.

## License
BSD-3-Clause. See [LICENSE](LICENSE)
