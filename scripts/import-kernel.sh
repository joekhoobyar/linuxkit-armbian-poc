#!/bin/bash -eu

: ${BOARD="odroidxu4"}
: ${LINUX_DOCKER_ARCH="arm/v7"}
: ${IMAGE_REPO="joekhoobyar/linuxkit-kernel"}
: ${KERNEL_VERSION="5.4.160"}
: ${ARMBIAN_UBUNTU_VERSION="21.08.6"}

(
    cd scripts/armbian && 
    ./kernel.sh "$BOARD" "$LINUX_DOCKER_ARCH" "$IMAGE_REPO" "$KERNEL_VERSION" "$ARMBIAN_UBUNTU_VERSION"
)
