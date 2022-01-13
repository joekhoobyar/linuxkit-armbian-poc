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

  cp ../ext-bin/empty-128mb.ext4 rootfs.ext4

  qemu-system-${ARCH} \
    -cpu cortex-a15 -machine type=vexpress-a15 -smp 2 -m 2G \
    -dtb ../ext-bin/vexpress-v2p-ca15-tc1.dtb \
    -uuid 60c2fbce-4e3e-4390-9241-ee425e1caefc \
    -pidfile "${STATE}/qemu.pid" \
    -serial mon:stdio -nic user,ipv6=off,hostfwd=tcp::5555-:22 \
    -drive if=sd,driver=file,filename=rootfs.ext4 \
    -kernel ${prefix}-kernel -initrd ${prefix}-initrd.img \
    -append 'console=tty0 console=ttyS0 console=ttyAMA0'
    # -device virtio-rng-pci
    # -net nic,model=virtio,macaddr=16:da:11:b4:44:c9
)
