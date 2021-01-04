# Quickstart

Installing a Linux distribution on a physical machine using Sheep basically consists in runnning a single script
that will perform Linux installation in a fully automated way. The sheep script only needs a configuration file describing the Linux distribution you aim to install.

## Write a Sheep configuration

Here is a minimalist Sheep YAML configuration

```yaml
bootloader:
  image: http://replace/by/real/path/grub.tar.gz

linux:
  image: https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
  label: Ubuntu 16.04 LTS

network:
  interfaces:
    - id: ens1
      type: dhcp

environment:
  users:
    - name: linux
      sudoer: true
      password: linux
      ssh_authorized_key: ssh-rsa ...
  local_hostname: linux
```

In this example, we use an official Ubuntu qcow2 cloud image. The bootloader image is only needed when your machine runs an UEFI firmware. When in BIOS (Legacy) mode, you can basically remove the bootloader section.

## Setup the execution environment

The purpose of Sheep is to install Linux from Linux. That means you need your system to run Linux to install Linux on your local drive. That is the purpose of Sheep Live, a Live Linux distribution made to run Sheep.

As Sheep primarily makes sense in a fully automated environement, Sheep Live provides artifacts to easily boot over the network.

Download the Sheep Live kernel, initrd and root filesystem binaries [here](https://github.com/sheeplinux/sheep-live/releases/latest).

Using these artifacts deployed on your TFTP/HTTP server, you can write a configuration to boot Sheep Live.

**Example using pxelinux/syslinux**

```text
default sheep
label sheep
    kernel /sheep-live/vmlinuz
    append boot=live fetch=http://netserver/sheep-live.squashfs initrd=/sheep-live/initrd.img ssh=sheep sheep.script=http://netserver/sheep sheep.config=http://netserver/ubuntu-16.04-leopard.yml startup=/usr/bin/sheep-service
```

To learn more about Sheep Live, please refer to [Sheep live environment](https://sheeplinux.github.io/sheep/sheep-live/) page.

## Run Sheep

Once Sheep Live is up and running, it automatically runs the Linux installation process using Sheep and then reboot the machine when installation complete.

If for any reason you want to prevent Sheep to run automatically (e.g. to debug or run manually) you only have to remove the `startup` kernel parameter on the command line.
