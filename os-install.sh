#!/bin/bash

set -x
set -e

BOOT_SERVER="172.19.118.1"
PUBLIC_IFACE_NAME="ens1"
PXE_PILOT_BASEURL="http://${BOOT_SERVER}:3478"
LINUX_ROOTFS_URL="http://${BOOT_SERVER}/distrib/ubuntu1604_root.tar.gz"
EFI_ARCHIVE_URL="http://${BOOT_SERVER}/distrib/efi.tar.gz"
EFI_ENTRY_LABEL="Ubuntu 16.04"
BLOCK_DEVICE="/dev/sda"
BOOTLOADER_EFI_PATH="\EFI\ubuntu\shimx64.efi"

EFI_PARTITION="${BLOCK_DEVICE}1"
LINUX_PARTITION="${BLOCK_DEVICE}2"

#
# Create two partitions on the drive. One system EFI partition to install
# the bootloader nad on for the Linux root filesystem. If some partitions
# previoulsly exist on the drive everything is wiped beforehand.
#
system_partitionning() {
    echo ' ' ; echo 'Partitioning' ; echo ' '
    gdisk ${BLOCK_DEVICE} <<- EOF
	o
	Y
	n
	1

	+500M
	ef00
	n
	2


	8300
	wq
	yes
	EOF
}

partitions_formating() {
    echo ' ' ; echo 'Formating' ; echo ' '
    mkfs.fat -F 32 -n EFI ${EFI_PARTITION}
    mkfs.ext4 -q -L fs_root ${LINUX_PARTITION} <<- EOF
	y
	EOF
}

partitions_mounting() {
    mount ${LINUX_PARTITION} /mnt
    mkdir -p /mnt/boot/efi
    mount ${EFI_PARTITION} /mnt/boot/efi
}

bootloader_installation() {
    cd /mnt/boot/efi
    local efi_archive=efi.tar.gz
    wget --quiet -O ${efi_archive} ${EFI_ARCHIVE_URL}
    tar -pzxf ${efi_archive}
    rm ${efi_archive}
}

efi_entry_creation() {
    efibootmgr -c -d ${BLOCK_DEVICE} -p 1 -L "${EFI_ENTRY_LABEL}" -l "${BOOTLOADER_EFI_PATH}" 
}

linux_rootfs_installation() {
    cd /mnt
    local linux_rootfs=/tmp/linux-rootfs.tar.gz
    wget --quiet -O ${linux_rootfs} ${LINUX_ROOTFS_URL}
    tar -pzxf ${linux_rootfs}
    rm ${linux_rootfs}
}

linux_rootfs_configuration() {
    uuid=$(blkid | grep ${LINUX_PARTITION} | cut -d ' ' -f 3 | cut -d '"' -f 2)
    efiID=$(blkid | grep ${EFI_PARTITION} | cut -d ' ' -f 4 | cut -d '"' -f 2)
    sed -i -e 's/rootID/'$uuid'/' /mnt/boot/grub/grub.cfg
    sed -i -e 's/rootID/'$uuid'/' /mnt/boot/efi/EFI/ubuntu/grub.cfg
    sed -i -e 's/efiID/'$efiID'/' /mnt/etc/fstab
    sed -i -e 's/rootID/'$uuid'/' /mnt/etc/fstab
}

partitions_unmounting() {
    cd /
    umount -R /mnt
}

notify_pxepilot_and_reboot() {
    macA=$(ip address | grep -A 1 "${PUBLIC_IFACE_NAME}" | grep "link/ether" | cut -d ' ' -f 6)
    curl -i -X PUT "${PXE_PILOT_BASEURL}/v1/configurations/local/deploy" -d '{"hosts":[{"macAddress":"'"$macA"'"}]}'
    reboot
}

{
    system_partitionning
    partitions_formating
    partitions_mounting
    linux_rootfs_installation
    bootloader_installation
    efi_entry_creation
    linux_rootfs_configuration
    partitions_unmounting
    notify_pxepilot_and_reboot
} 2>&1 | tee /var/log/os-install.log
