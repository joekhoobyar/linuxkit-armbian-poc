#!/bin/bash -eu
# shellcheck disable=SC1091
# shellcheck disable=SC2223

source scripts/_functions.sh

: ${BOARD=odroidxu4}
export BOARD
source scripts/_boards.sh

IMAGE_ORG="dockerregistry.lab.khoobyar.lan/linuxkit"
IMAGE_REPO="$IMAGE_ORG/alpine"
IMAGE_HASH="$(cat linuxkit/tools/alpine/hash)" 
IMAGE_HASH="${IMAGE_HASH%-*}"
ALPINE_BASE="$IMAGE_REPO:$IMAGE_HASH-$ARCHX"
export IMAGE_ORG IMAGE_REPO IMAGE_HASH ALPINE_BASE

# The init package build hangs when using buildkitd's qemu-system-arm.
DEFAULT_PACKAGES=( runc containerd ca-certificates sysctl dhcpcd getty rngd )

cmd="$1" ; shift
case "$cmd" in
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
