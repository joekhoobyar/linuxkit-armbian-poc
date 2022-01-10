#!/bin/bash -eu
# shellcheck disable=SC1091
# shellcheck disable=SC2223

source scripts/_functions.sh

: ${BOARD=odroidxu4}
export BOARD
source scripts/_boards.sh

IMAGE_ORG="harbor.lab.khoobyar.lan/linuxkit"
ALPINE_REPO="$IMAGE_ORG/alpine"
export IMAGE_ORG ALPINE_REPO

: ${BUILDX_ARGS=}

# The init package build hangs when using buildkitd's qemu-system-arm.
DEFAULT_PACKAGES=( runc containerd ca-certificates sysctl dhcpcd getty rngd sshd )

cmd="$1" ; shift
case "$cmd" in
import-kernel)
  import-kernel-$BOARD
  ;;
base)
  linuxkit_alpine_build
  ;;
pkg)
  pkg="$1" ; shift
  linuxkit_pkg_build "$pkg"
  ;;
all-pkg)
  for pkg in "${DEFAULT_PACKAGES[@]}"
  do linuxkit_pkg_build "$pkg"
  done
  ;;
*)
  die 'invalid command'
  ;;
esac
