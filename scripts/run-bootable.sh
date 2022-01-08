#!/bin/bash -eu

: ${ARCH=arm}
: ${BOARD=odroidxu4}
: ${BACKEND=qemu}

(
  cd target && 
  mkdir -p testrun &&
  sudo linuxkit run ${BACKEND} \
    -arch ${ARCH} -cpus 2 -mem 2048 -state testrun \
    linuxkit-${BOARD}
)

