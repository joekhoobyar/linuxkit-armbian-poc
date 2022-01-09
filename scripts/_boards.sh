#!/bin/bash -eu
# shellcheck disable=SC2223

case "$BOARD" in
odroidxu[34])
  : ${ARCH=arm}
  : ${ARCHX=armv7l}
  : ${DOCKER_PLATFORM=linux/arm/v7}
  ;;
esac

export ARCH ARCHX DOCKER_PLATFORM
