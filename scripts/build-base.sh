#!/bin/bash -eu
#
# Alpine Base
#
# A few patches to cross-build for arm32 (we are using binfmt_misc with qemu)
# 
#  - Override ARCH seen by make
#  - Override DOCKER_DEFAULT_PLATFORM
#  - Specify packages for armv7l
#  - Remove zfs (there is no armv7l package for it)

: ${ARCH=armv7l}
: ${DOCKER_DEFAULT_PLATFORM=linux/arm/v7}

export ARCH DOCKER_DEFAULT_PLATFORM

(
    cd linuxkit/tools/alpine &&
    sed -e 's/^ARCH := /ARCH?=/g' -i~ Makefile && rm -f Makefile~ &&
    sed -e '/zfs/d' -i~ packages && rm -f packages~ &&
    cp packages.{aarch64,armv7l} &&
    make build
)

IMAGE_ORG="joekhoobyar"
IMAGE_HASH="$(cat linuxkit/tools/alpine/hash)" 
ALPINE_BASE="$IMAGE_ORG/linuxkit-alpine:${IMAGE_HASH%-*}-$ARCH"
docker tag "linuxkit/alpine:$IMAGE_HASH" "$ALPINE_BASE"
docker push "$ALPINE_BASE"
