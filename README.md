# ungoogled-chromium-portablelinux
Portable Linux (`.AppImage`) packaging for [ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium).

## Downloads
- [Download binaries from GitHub Releases](https://github.com/ungoogled-software/ungoogled-chromium-portablelinux/releases).
- [Download binaries from the Contributor Binaries website](https://ungoogled-software.github.io/ungoogled-chromium-binaries/).

## Building
To build the binary, run `scripts/docker-build.sh` from the repo root.

The `scripts/docker-build.sh` script will:
1. Create a Docker image of a Debian-based building environment with all required packages (llvm, nodejs and distro packages) included.
2. Run `scripts/build.sh` inside the Docker image to build ungoogled-chromium.

Running `scripts/build.sh` directly will not work unless you're running a Debian-based distro and have all necessary dependencies installed. This repo is designed to avoid having to configure the building environment on your Linux installation.

### Packaging
After building, run `scripts/package.sh`. Alternatively, you can run `package/docker-package.sh` to build inside a Docker image.

Either of these scripts will create `tar.xz` and `AppImage` files under `build/`.

### Development
By default, the build script uses tarball. If you need to use a source tree clone, you can run `scripts/docker-build.sh -c` instead. This may be useful if a tarball for a release isn't available yet.

## License
BSD-3-Clause. See [LICENSE](LICENSE)
