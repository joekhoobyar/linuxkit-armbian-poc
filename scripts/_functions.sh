#!/bin/bash -eu

out() { echo "$0:" "$@" ; }
err() { out "$@" 1>&2 ; }
die() { err "$@" ; exit 1 ; }

buildx-build() {
  local name="$1" tag="$2" buildx_args ; shift ; shift

  buildx_args=( --platform "$DOCKER_PLATFORM" -t "$IMAGE_ORG/$name:$tag" "$@" )

  if [ -z "${DISABLE_CACHE:-}" ]; then
    import_target="type=registry,ref=$IMAGE_ORG/$name:$tag"
    export_target="type=inline"
    buildx_args=( --cache-from="$import_target" --cache-to="$export_target" "${buildx_args[@]}" )
  fi

  out "$pkg: docker buildx build" "${buildx_args[@]}"
  docker buildx build "${buildx_args[@]}"
}

armbian-import-kernel() {
  local version="$1"
  local release="$2"
  local base_url="https://armbian.hosthatch.com/apt/pool/main/l"

  kernel_deb="$base_url/linux-${version}-${BOARD}/linux-image-current-${BOARD}_${release}_${DEB_ARCH}.deb"
  kernel_dtb_deb="${base_url}/linux-${version}-${BOARD}/linux-dtb-current-${BOARD}_${release}_${DEB_ARCH}.deb"
  headers_deb="$base_url/linux-${version}-${BOARD}/linux-headers-current-${BOARD}_${release}_${DEB_ARCH}.deb"
  uboot_deb="${base_url}/linux-u-boot-${BOARD}-current/linux-u-boot-current-${BOARD}_${release}_${DEB_ARCH}.deb"

  debian-import-kernel "$BOARD" "$version-$release" "${kernel_deb} ${kernel_dtb_deb} ${headers_deb} ${uboot_deb}"
}

debian-import-kernel() {
  local board="$1" version="$2" deb_urls="$3"
  local image_tag="${IMAGE_ORG}/kernel:${board}-${version}"

  (
    set -eu

    cd scripts/kernel-import

    docker build --progress plain --platform "$DOCKER_PLATFORM" --no-cache \
      --build-arg DEB_URLS="${deb_urls}" -t "$image_tag" -f Dockerfile.debian .

    docker push "${image_tag}"
  )
}

linuxkit_alpine_build() {
  (
    set -eu

    cd linuxkit/tools/alpine

    # Patches for the build - and 32-bit arm support.
    sed -e 's/^ARCH := /ARCH?=/g' -i~ Makefile && rm -f Makefile~
    sed -e '/zfs/d' -i~ packages && rm -f packages~
    cp packages.{aarch64,armv7l}

    # Use buildx to to build the image.
    hash="$(git rev-parse HEAD)-${ARCHX}"
    buildx-build alpine "$hash" --push .

    # Output information about the image
    echo "$ALPINE_REPO:$hash" >./iid
    echo "$hash" >./hash
  )
}

# Emulates: linuxkit pkg build (due to lack of arm support)
linuxkit_pkg_build() {
  local pkg="$1"

  hash="$(cat linuxkit/tools/alpine/hash)" 
  ALPINE_BASE="$ALPINE_REPO:$hash"

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
    buildx-build "$pkg" "$hash" ${BUILDX_ARGS:-} "${buildx_args[@]}" --push "$pkg"
    out "$pkg: built"
  )
}

linuxkit_build() {
  (
    cd target && 
    linuxkit build -arch "$ARCH" -docker -format kernel+initrd -name "linuxkit-$BOARD" "../$BOARD.yml"
  )
}