# End Goals

A 32-bit ARM build for linuxkit, capable of being used with tinkerbell's hook.  So we can do "Metal-as-a-service" with Armbian systems.

# Prequisites

- docker-buildx plugin for docker is needed.
- you a running buildkitd that can target arm32

# Building

## Kernels

### Kernel for qemu emulation (vexpress-a15)

For now, just a binary import of the kernel files (to be tested)

```
scripts/build.sh import-kernel vexpress-a15
```

### Kernel for Odroid XU4 (untested)

For now, just a binary import of the kernel files (to be tested)

```
scripts/build.sh import-kernel odroid-xu4
```

## Base dependencies

```
scripts/build.sh basee
```

## All packages

```
scripts/build.sh all-pkg
```

## Individual packages

```
scripts/build.sh pkg runc
```
