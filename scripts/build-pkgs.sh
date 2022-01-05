#!/bin/bash -eu

: ${ARCH=armv7l}
: ${DOCKER_DEFAULT_PLATFORM=linux/arm/v7}

export ARCH DOCKER_DEFAULT_PLATFORM

IMAGE_ORG="joekhoobyar"
IMAGE_REPO="$IMAGE_ORG/linuxkit-alpine"
IMAGE_HASH="$(cat linuxkit/tools/alpine/hash)" 
IMAGE_HASH="${IMAGE_HASH%-*}"
ALPINE_BASE="$IMAGE_REPO:$IMAGE_HASH-$ARCH"

# PACKAGES=( sysctl )
PACKAGES=( init runc containerd ca-certificates sysctl dhcpcd getty rngd )

for pkg in "${PACKAGES[@]}"
do (
  cd linuxkit

  # Attempt to apply a patch
  echo "$0: $pkg: patching ..."
  patch="../patches/linuxkit-pkg-$pkg-$ARCH.patch"
  if [ -f "$patch" ]; then patch -lN -p1 -i "$patch" || true ; fi
  echo "$0: $pkg: patched"

  # Attempt to "reparent" the image
  cd pkg/"$pkg"
  echo "$0: $pkg: reparenting ..."
  sed -e 's@FROM .*linuxkit[-/]alpine:.* [Aa][Ss]@FROM '"$ALPINE_BASE"' AS@g' -i~ Dockerfile && rm -f Dockerfile~
  echo "$0: $pkg: reparented"

  # Attempt to configure the build.
  buildx_args=( \
    --platform "$DOCKER_DEFAULT_PLATFORM" \
    -t "$IMAGE_ORG/linuxkit-$pkg:$IMAGE_HASH-$ARCH" \
    --label=org.mobyproject.linuxkit.version="unknown" \
    --label=org.mobyproject.linuxkit.revision="unknown" \
  )
  network="$(yq .network <build.yml | jq -r .)"
  if [ "$network" = "null" ] || [ "$network" = "false" ]; then
    buildx_args=( "${buildx_args[@]}" --network=none )
  fi
  moby_config="$(yq .config <build.yml | jq .)"
  if [ "$moby_config" != "null" ]; then
    buildx_args=( "${buildx_args[@]}" --label=org.mobyproject.config="$moby_config" )
  fi

  # Attempt to build and push image
  echo "$0: $pkg: building ..."
  cd ..
  docker buildx build "${buildx_args[@]}" "$pkg"
  # linuxkit pkg build --platforms "linux/$ARCH" --hash "$IMAGE_HASH" --org "$IMAGE_ORG" --disable-cache "$pkg"
  echo "$0: $pkg: built"

  echo "$0: $pkg: pushing ..."
  # docker tag "$IMAGE_ORG/$pkg:$IMAGE_HASH-$ARCH"
  # docker rmi "$IMAGE_ORG/$pkg:$IMAGE_HASH-$ARCH"
  docker push "$IMAGE_ORG/linuxkit-$pkg:$IMAGE_HASH-$ARCH"
  echo "$0: $pkg: pushed"
)
done
