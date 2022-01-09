#!/bin/bash -eu
# shellcheck disable=SC2223

case "$BOARD" in
odroidxu4|vexpress-a15)
  : ${ARCH=arm}
  : ${DEB_ARCH=armhf}
  : ${ARCHX=armv7l}
  : ${DOCKER_PLATFORM=linux/arm/v7}
  ;;
*)
  die "$BOARD: unsupported board"
  ;;
esac

export ARCH ARCHX DEB_ARCH DOCKER_PLATFORM

import-kernel-odroidxu4() {
  armbian-import-kernel 5.4.160 21.08.6
}

import-kernel-vexpress-a15() {
  local version="5.4.0"
  local patch="92"
  local release="103"
  local base_url="http://launchpadlibrarian.net"

  # https://launchpad.net/ubuntu/focal/+package/linux-image-5.4.0-92-generic-lpae
  kernel_deb="$base_url/570969915/linux-image-$version-$patch-generic-lpae_$version-$patch.${release}_armhf.deb"

  # https://launchpad.net/ubuntu/focal/armhf/linux-modules-5.4.0-92-generic-lpae/5.4.0-92.103
  modules_deb="$base_url/570969874/linux-modules-$version-$patch-generic-lpae_$version-$patch.${release}_armhf.deb"

  # https://launchpad.net/ubuntu/focal/armhf/linux-headers-5.4.0-92-generic-lpae/5.4.0-92.103
  headers_deb="$base_url/570969834/linux-headers-$version-$patch-generic-lpae_$version-$patch.${release}_armhf.deb"

  debian-import-kernel "$BOARD" "$version-$patch.$release" "${kernel_deb} ${modules_deb} ${headers_deb}"
}
