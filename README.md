# OS Deploy Tool

The aim of this project is to provide a tool to install any Linux distribution from a running Linux operating system
in an automated way implementing a standard process. It also provide good efficiency in term of execution time.

Usually, every single distribution comes with its own installation process and its own tools for installation automation. Here, we propose an installation process that will be always the same whatever your distribution is. In some cases, the tool
implements some speficities depending on the operating system but it is totally transparent for the end user.

It have been successfully tested with the following distributions

- Ubuntu 16.04
- Ubuntu 18.04
- CentOS 7
- Debian 9
- Fedora 28
- Fedora 29
- Fedora 30
- OpenSuse Leap 15.0
- OpenSuse Leap 15.1

## How it works

The main idea is to avoid using vendor installer programs and execute by ourself necessary steps to install the Linux operating system.

### Prerequisites

In order to run this tool, your server needs to be booted on a live Linux distribution. So far, it has been tested
on GRML 2018.12 only.

### Installation process

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

## Current limitations

This project is at a early stage and it currently comes with some limitation

- It works only in UEFI mode not in Legacy (MBR) mode
- It does not support multiboot

## PXE Pilot integration

Using PXE Pilot with DNSMASQ and Syslinux EFI bootloader we are able to provide a CLI-based userfriendly interface
to manage many servers and re-image any machine using a one line command.
