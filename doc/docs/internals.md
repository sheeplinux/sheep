## Internals

This section describes how Sheep works internally.

## Installation process in UEFI boot mode

Here are the steps executed by this tool in order to install a Linux distribution

1. Wipe the target drive (every single partition is deleted)
2. Create three GPT partitions
    - The EFI System partition
    - The cloud-init partition
    - The Linux root filesystem partition
3. Format partitions using the appropriate filesystem
4. Mount partitions
5. Get Linux root filesystem image and extract it
6. Get EFI bootloader and install it
7. Create boot entry in the EFI boot manager
8. Write the grub menu
9. Configure the Linux root filesystem using cloud-init
10. Unmount partitions
11. Reboot the machine

## Installation process in legacy boot mode

Here are the steps executed by this tool in order to install a Linux distribution

1. Wipe the target drive (every single partition is deleted)
2. Create two GPT partitions
    - The cloud-init partition
    - The Linux root filesystem partition
3. Format partitions using the appropriate filesystem
4. Mount partitions
5. Get Linux root filesystem image and extract it
6. Write the MBR partition using grub-install
7. Write the grub menu
8. Configure the Linux root filesystem using cloud-init
9. Unmount partitions
10. Reboot the machine

The full process run in a couple of seconds when using a `tar.gz` or `tar.xz` a root filesystem archive. It takes additionnal time (depending on your CPU performance) when extracting Qcow2 
