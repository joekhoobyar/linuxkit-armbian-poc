#!/bin/bash -eu

out() { echo "$0:" "$@" ; }
err() { out "$@" 1>&2 ; }
die() { err "$@" ; exit 1 ; }

linuxkit_alpine_build() {
  (
    cd linuxkit/tools/alpine &&
    sed -e 's/^ARCH := /ARCH?=/g' -i~ Makefile && rm -f Makefile~ &&
    sed -e '/zfs/d' -i~ packages && rm -f packages~ &&
    cp packages.{aarch64,armv7l} &&
    DOCKER_DEFAULT_PLATFORM="$DOCKER_PLATFORM" make build &&
    docker tag "linuxkit/alpine:$IMAGE_HASH" "$ALPINE_BASE"
    docker push "$ALPINE_BASE" &&
    echo "$ALPINE_BASE" >./hash
  )
}

# Emulates: linuxkit pkg build (due to lack of arm support)
linuxkit_pkg_build() {
  local pkg="$1"

  (
    set -eu

    cd linuxkit

    # Attempt to apply a patch
    out "$pkg: patching ..."
    patch="../patches/linuxkit-pkg-$pkg-$ARCHX.patch"
    if [ -f "$patch" ]; then patch -lN -p1 -i "$patch" || true ; fi
    out "$pkg: patched"

    # Attempt to "reparent" the image
    cd pkg/"$pkg"
    out "$pkg: reparenting ..."
    sed -e 's@FROM .*linuxkit[-/]alpine:.* [Aa][Ss]@FROM '"$ALPINE_BASE"' AS@g' -i~ Dockerfile && rm -f Dockerfile~
    out "$pkg: reparented"

    # Attempt to configure the build.
    buildx_args=( \
      --platform "$DOCKER_PLATFORM" \
      -t "$IMAGE_ORG/$pkg:$IMAGE_HASH-$ARCH" \
      --label=org.mobyproject.linuxkit.version="unknown" \
      --label=org.mobyproject.linuxkit.revision="unknown" \
    )
    network="$(yq -o json eval <build.yml | jq -r .network)"
    if [ "$network" = "null" ] || [ "$network" = "false" ]; then
      buildx_args=( "${buildx_args[@]}" --network=none )
    fi
    moby_config="$(yq -o json eval <build.yml | jq .config)"
    if [ "$moby_config" != "null" ]; then
      buildx_args=( "${buildx_args[@]}" --label=org.mobyproject.config="$moby_config" )
    fi

    # Attempt to build and push image
    out "$pkg: building ..."
    cd ..
    docker buildx build "${buildx_args[@]}" --no-cache --push "$pkg"
    out "$pkg: built"
  )
}

linuxkit_build() {
  (
    cd target && 
    linuxkit build -arch arm -docker -format kernel+initrd -name linuxkit-$BOARD ../$BOARD.yml
  )
}