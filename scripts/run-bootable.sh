#!/bin/bash -eu

: ${ARCH=arm}
: ${BOARD=odroidxu4}
: ${BACKEND=qemu}
: ${STATE=./testrun}
: ${UUIDFILE="${STATE}/uuid"}

prefix="linuxkit-${BOARD}"

(
  set -eu

  cd target
  mkdir -p "$STATE"

  if [ -f "$UUIDFILE" ]; then
    UUID="$(cat "$UUIDFILE")"
  else
    UUID="$(uuidgen)"
    echo -n "$UUID" > "$UUIDFILE"
  fi

  qemu-system-${ARCH} \
    -cpu cortex-a15 -machine smdkc210 -smp 2 -m 2048 \
    -uuid 60c2fbce-4e3e-4390-9241-ee425e1caefc \
    -pidfile "${STATE}/qemu.pid" \
    -net user \
    -nographic \
    -kernel ${prefix}-kernel -initrd ${prefix}-initrd.img
    # -device virtio-rng-pci
    # -net nic,model=virtio,macaddr=16:da:11:b4:44:c9
    # -append 'console=tty0 console=ttyS0 console=ttyAMA0'
)

