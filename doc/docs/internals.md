## Internals

This section describes how Sheep works internally.

## Installation process

Here are the steps executed by this tool in order to install a Linux distribution

1. Wipe the target drive (every single partition is deleted)
2. Create two GPT partitions
    - The EFI System partition
    - The Linux root filesystem partition
3. Format partitions using the appropriate filesystem
4. Mount partitions
5. Get Linux root filesystem image and extract it
6. Get EFI bootloader and install it
7. Configure the bootloader and the Linux root filesystem
8. Create boot entry in the EFI boot manager
9. Unmount partitions
10. Reboot the machine

The full process run in a couple of seconds when using a `tar.gz` or `tar.xz` a root filesystem archive. It takes additionnal time (depending on your CPU performance) when extracting Qcow2 filesystem.

The step 7. is the only one where implementation can differ depending on the Linux distribution.
