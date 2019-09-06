#!/bin/bash

set -x
set -e

{
echo $("Ubuntu.16.04")
# STEP 1 : Partionning ( clear the disk if it's not erased )
echo ' ' ; echo 'Partitioning' ; echo ' '
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk /dev/sda
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

#STEP 2 : Formating partitions
echo ' ' ; echo 'Formating' ; echo ' '
mkfs.fat -F 32 -n EFI /dev/sda1
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | mkfs.ext4 -q -L fs_root /dev/sda2
y
EOF

#STEP 3 : Mounting partions & Copy of root and EFI 
echo ' ' ; echo 'Mounting & Copying' ; echo ' '
mount /dev/sda2 /mnt
cd /mnt
wget --quiet http://172.19.118.1/distrib/ubuntu1604_root.tar.gz
tar -pzxf ubuntu1604_root.tar.gz
cd --
cp -Rp /mnt/mnt/* /mnt ; rm -r /mnt/mnt
rm /mnt/ubuntu1604_root.tar.gz
mount /dev/sda1 /mnt/boot/efi
cd /mnt/boot/efi
wget --quiet http://172.19.118.1/distrib/efi.tar.gz
tar -pzxvf efi.tar.gz
mkdir tmp
cp -Rp ./efi/* ./tmp ; rm -r efi
cp -Rp tmp/* /mnt/boot/efi ; rm -r tmp
rm efi.tar.gz
cd --
#STEP 4 : Correction of grub.cfg & fstab
echo ' ' ; echo 'last configuration' ; echo ' '
uuid=$(blkid | grep /dev/sda2 | cut -d ' ' -f 3 | cut -d '"' -f 2)
efiID=$(blkid | grep /dev/sda1 | cut -d ' ' -f 4 | cut -d '"' -f 2)
sed -i -e 's/rootID/'$uuid'/' /mnt/boot/grub/grub.cfg
sed -i -e 's/rootID/'$uuid'/' /mnt/boot/efi/EFI/ubuntu/grub.cfg
sed -i -e 's/efiID/'$efiID'/' /mnt/etc/fstab
sed -i -e 's/rootID/'$uuid'/' /mnt/etc/fstab
efibootmgr -c -d /dev/sda -p 1 -L "Lancer ubuntu" -l "\EFI\ubuntu\shimx64.efi"
macA=$(ip address | grep -A 1 "ens1" | grep "link/ether" | cut -d ' ' -f 6)
curl -i -X PUT "http://172.19.118.1:3478/v1/configurations/local/deploy" -d '{"hosts":[{"macAddress":"'"$macA"'"}]}'
umount -R /mnt
reboot
} 2>&1 | tee /var/log/os-install.log
