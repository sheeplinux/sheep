#!/bin/bash

set -x
set -e

#
# Create tow partitions on the drive. One system EFI partition to install
# the bootloader nad on for the Linux root filesystem. If some partitions
# previoulsly exist on the drive everything is wiped beforehand.
#
system_partitionning() {
    echo ' ' ; echo 'Partitioning' ; echo ' '
    gdisk /dev/sda << EOF
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
    mkfs.fat -F 32 -n EFI /dev/sda1
    mkfs.ext4 -q -L fs_root /dev/sda2 << EOF
y
EOF
}

partitions_mounting() {
    mount /dev/sda2 /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/sda1 /mnt/boot/efi
}

bootloader_installation() {
    cd /mnt/boot/efi
    wget --quiet http://172.19.118.1/distrib/efi.tar.gz
    tar -pzxvf efi.tar.gz
    mkdir tmp
    cp -Rp ./efi/* ./tmp ; rm -r efi
    cp -Rp tmp/* /mnt/boot/efi ; rm -r tmp
    rm efi.tar.gz
}

efi_entry_creation() {
    efibootmgr -c -d /dev/sda -p 1 -L "Lancer ubuntu" -l "\EFI\ubuntu\shimx64.efi"
}

linux_rootfs_installation() {
    cd /mnt
    wget --quiet http://172.19.118.1/distrib/ubuntu1604_root.tar.gz
    tar -pzxf ubuntu1604_root.tar.gz
    cd --
    cp -Rp /mnt/mnt/* /mnt ; rm -r /mnt/mnt
    rm /mnt/ubuntu1604_root.tar.gz
    cd --
}

linux_rootfs_configuration() {
    uuid=$(blkid | grep /dev/sda2 | cut -d ' ' -f 3 | cut -d '"' -f 2)
    efiID=$(blkid | grep /dev/sda1 | cut -d ' ' -f 4 | cut -d '"' -f 2)
    sed -i -e 's/rootID/'$uuid'/' /mnt/boot/grub/grub.cfg
    sed -i -e 's/rootID/'$uuid'/' /mnt/boot/efi/EFI/ubuntu/grub.cfg
    sed -i -e 's/efiID/'$efiID'/' /mnt/etc/fstab
    sed -i -e 's/rootID/'$uuid'/' /mnt/etc/fstab
}

partitions_unmounting() {
    cd
    umount -R /mnt
}

notify_pxepilot_and_reboot() {
    macA=$(ip address | grep -A 1 "ens1" | grep "link/ether" | cut -d ' ' -f 6)
    curl -i -X PUT "http://172.19.118.1:3478/v1/configurations/local/deploy" -d '{"hosts":[{"macAddress":"'"$macA"'"}]}'
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
