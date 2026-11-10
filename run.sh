#!/bin/bash
# run.sh

KERNEL_IMG=../linux/arch/x86/boot/bzImage
ROOTFS_IMG=../buildroot/output/images/rootfs.ext2
INITRD_IMG=../initramfs.cpio.gz

DRIVER_DIR=$(pwd)

# Select rootfs / initrd options
BOOT_OPTS=()
if [ -f "$ROOTFS_IMG" ]; then
    BOOT_OPTS+=(-drive file="$ROOTFS_IMG",format=raw,index=0,media=disk -append "root=/dev/sda console=ttyS0")
elif [ -f "$INITRD_IMG" ]; then
    BOOT_OPTS+=(-initrd "$INITRD_IMG" -append "console=ttyS0 quiet panic=1")
else
    echo "Error: Neither $ROOTFS_IMG nor $INITRD_IMG found!"
    exit 1
fi

# Enable KVM acceleration if user has permission
KVM_OPTS=()
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    KVM_OPTS+=(-enable-kvm)
else
    echo "Note: KVM acceleration unavailable (/dev/kvm permission). Running via emulation..."
fi

echo "Starting QEMU VM..."
echo "To exit QEMU anytime, press: Ctrl-A then X"

qemu-system-x86_64 \
    -kernel "$KERNEL_IMG" \
    "${BOOT_OPTS[@]}" \
    -fsdev local,id=share,path="$DRIVER_DIR",security_model=passthrough \
    -device virtio-9p-pci,fsdev=share,mount_tag=host_share \
    -serial stdio \
    -display none \
    "${KVM_OPTS[@]}" \
    -m 2G

echo "QEMU VM has shut down."
