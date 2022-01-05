#! /bin/sh

if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <board> <platform> <org/repo> <kernel version> <sub version>"
    echo
    echo "Example:"
    echo "$0 odroidxu4 arm/v7 foobar/kernel-armbian 5.4.160 21.08.6"
    echo
    echo "This will create a local LinuxKit kernel package:"
    echo
    echo "  foobar/kernel-armbian:odroidxu4-4.14.0-21.08.6 (--platform linux/arm/v7)"
    echo
    echo "which you can then push to hub or just use locally"
    exit 1
fi

# List all available kernels with:
# curl -s https://armbian.hosthatch.com/apt/pool/main/l/linux-5.4.160-odroidxu4/ | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep -o "linux-image-[0-9]\.[0-9]\+\.[0-9]\+-[0-9]\+-odroidxu4_[^ ]\+amd64\.deb"

BOARD=$1
PLATFORM=$2
REPO=$3
VER1=$4
VER2=$5
URL="https://armbian.hosthatch.com/apt/pool/main/l"
ARCH=armhf

KERNEL_DEB="${URL}/linux-${VER1}-odroidxu4/linux-image-current-${BOARD}_${VER2}_${ARCH}.deb"
KERNEL_DTB_DEB="${URL}/linux-${VER1}-odroidxu4/linux-dtb-current-${BOARD}_${VER2}_${ARCH}.deb"
HEADERS_DEB="${URL}/linux-${VER1}-odroidxu4/linux-headers-current-${BOARD}_${VER2}_${ARCH}.deb"
UBOOT_DEB="${URL}//linux-u-boot-${BOARD}-current/linux-u-boot-current-${BOARD}_${VER2}_${ARCH}.deb"

DEB_URLS="${KERNEL_DEB} ${KERNEL_DTB_DEB} ${HEADERS_DEB} ${UBOOT_DEB}"

docker build --progress plain \
    --platform "linux/${PLATFORM}" \
    -t "${REPO}:${BOARD}-${VER1}-${VER2}" \
    -f Dockerfile.armbian \
    --no-cache \
    --build-arg DEB_URLS="${DEB_URLS}" .
docker push "${REPO}:${BOARD}-${VER1}-${VER2}"
