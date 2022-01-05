#!/bin/bash -eu

: ${ARCH=armv7l}
: ${DOCKER_DEFAULT_PLATFORM=linux/arm/v7}

export ARCH DOCKER_DEFAULT_PLATFORM

IMAGE_ORG="dockerregistry.lab.khoobyar.lan/linuxkit"
IMAGE_HASH="$(cat linuxkit/tools/alpine/hash)" 
# IMAGE_SUFFIX="${IMAGE_HASH##*-}"
ALPINE_BASE="$IMAGE_ORG/alpine:$IMAGE_HASH"

PACKAGES=( init sysctl dhcpcd getty rngd )

for pkg in "${PACKAGES[@]}"
do (
  cd linuxkit

  # Attempt to apply a patch
  echo "$0: $pkg: patching ..."
  patch="../patches/linuxkit-pkg-$pkg-$ARCH.patch"
  if [ -f "$patch" ]; then patch -lN -p1 -i "$patch" || true ; fi
  echo "$0: $pkg: patched"

  # Attempt to "reparent" the image
  cd pkg/"$pkg" &&
  echo "$0: $pkg: reparenting ..."
  sed -e 's@FROM linuxkit/alpine:.* AS@FROM '"$ALPINE_BASE"' AS@g' -i~ Dockerfile && rm -f Dockerfile~ &&
  echo "$0: $pkg: reparented"

  # Attempt to build and push image
  echo "$0: $pkg: building ..."
  docker build --no-cache -t "$IMAGE_ORG/$pkg:$IMAGE_HASH" .
  echo "$0: $pkg: built"

  echo "$0: $pkg: pushing ..."
  docker push "$IMAGE_ORG/$pkg:$IMAGE_HASH"
  echo "$0: $pkg: pushed"
)
done
