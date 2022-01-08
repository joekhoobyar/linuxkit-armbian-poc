#!/bin/bash -eu

: ${ARCH=arm}
: ${BOARD=odroidxu4}

(cd target && 
  linuxkit build -arch arm -docker -format kernel+initrd -name linuxkit-${BOARD} ../${BOARD}.yml)
