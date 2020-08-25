#!/bin/bash -eux

# Verifies that GNU patch is installed -- CI checks fail if a patch is used to add
#  support for busybox, and GNU patch is available on all major musl-based distros

if [ -L "$(which patch)" ] && [ "$(readlink $(which patch))" = "/bin/busybox" ]; then
  echo "Error: busybox patch is not supported, please install GNU patch before continuing."
  exit 1
fi
