# Building


For odroidxu4 (arm/v7)

## Kernel (import from Armbian)

```
(
    cd scripts/armbian && 
    ./kernel.sh odroidxu4 arm/v7 joekhoobyar/kernel-armbian 5.4.160 21.08.6
)
```

## Alpine Base

```
(
    cd linuxkit/tools/alpine &&
    sed -e '/zfs/d' -i~ packages && rm -f packages~ &&
    cp packages.{aarch64,armv7l} &&
    DOCKER_DEFAULT_PLATFORM=linux/arm/v7 make build
)
```

