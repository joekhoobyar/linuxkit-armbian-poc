# Building


Example: For odroidxu4 (arm/v7)

## Baseline dependencies

### Kernel (import from Armbian)

For now, just a binary import of the kernel files (to be tested)

```
(
    cd scripts/armbian && 
    ./kernel.sh odroidxu4 arm/v7 joekhoobyar/kernel-armbian 5.4.160 21.08.6
)
```

### Alpine Base

A few patches to cross-build for arm32 (we are using binfmt_misc with qemu)

 - Override ARCH seen by make
 - Override DOCKER_DEFAULT_PLATFORM
 - Specify packages for armv7l
 - Remove zfs (there is no armv7l package for it)

Then, we export the ALPINE_TAG in the environment

```
(
    cd linuxkit/tools/alpine &&
    sed -e 's/^ARCH := /ARCH?=/g' -i~ Makefile && rm -f Makefile~ &&
    sed -e '/zfs/d' -i~ packages && rm -f packages~ &&
    cp packages.{aarch64,armv7l} &&
    DOCKER_DEFAULT_PLATFORM=linux/arm/v7 ARCH=armv7l make build
)
export ALPINE_TAG=$(cat linuxkit/tools/alpine/hash)
```

## Init
