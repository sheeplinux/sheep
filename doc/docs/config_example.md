# Sheep configuration full examples

## Simplified

Below is an example of a Sheep configuration file in simplified mode.

```yaml
bootloader:
  kernel_parameter: 'console=ttyS1,115200n8'

linux:
  image: http://mirror_address/CentOS-7-x86_64-GenericCloud-1907.qcow2
  label: CentOS 7
  device: /dev/sda
  rootfsType: ext4
  rootfsLabel: centos-fs
  selinux: disable
  blacklist_module:
    - mei
    - mei_me

network:
  interfaces:
    - id: enp12s0
      type: dhcp
    - id: ens9
      type: static
      address: x.x.x.x
      gateway: x.x.x.x

pxePilot:
  enable: true
  url: http://pxe-pilot_server_address
  config_after_reboot: local

environment:
  users:
    - name: linux
      sudoer: true
      password: linux
      ssh_authorized_key: server_ssh_public_key
      shell: /bin/bash
  local_hostname: sheep

cloudInit:
  enable: false
  instance_id: 001-local01

sheep:
  reboot: false

```

## Cloud-init users oriented

Below is an example of a configuration file where appears clearly the configurable part of cloud-init.

```yaml
bootloader:
  kernel_parameter: 'console=ttyS1,115200n8'

linux:
  image: http://@@SHEEP_CI_RUNNER_IP@@/CentOS-7-x86_64-GenericCloud-1907.qcow2
  label: CentOS 7
  device: /dev/sda
  rootfsType: ext4
  rootfsLabel: centos-fs
  selinux: disable
  blacklist_module:
    - mei
    - mei_me

pxePilot:
  enable: true
  url: http://@@SHEEP_CI_RUNNER_IP@@:3478
  config_after_reboot: local

cloudInit:
  enable: true
  metaData:
    instance-id: 001-local01
    local-hostname: sheep
  networkConfig:
    version: 2
    ethernets:
      enp12s0:
        dhcp4: true
      ens9:
        addresses:
          - 172.19.17.111/24
        gateway4: 172.19.17.1
  userData:
    users:
      - name: linux
        lock_passwd: false
        ssh_authorized_keys: @@SHEEP_CI_SSH_PUB_KEY@@
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
    chpasswd:
      expire: false
      list: |
        linux:linux
    ssh_pwauth: true

sheep:
  reboot: false

```
