# Sheep configuration full examples

## Simplified

Below is an example of a Sheep configuration file in simplified mode.

```yaml
bootloader:
  kernel_parameter: 'console=ttyS1,115200n8'

linux:
  image: https://cloud.centos.org/centos/7/images/CentOS-7-aarch64-GenericCloud-2003.qcow2
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
  url: http://172.19.17.1:3478
  config_after_reboot: local

environment:
  users:
    - name: linux
      sudoer: true
      password: linux
      ssh_authorized_key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdXnRJVWf7OvFa0UZPkvDBave2BWhr29HFlO/bI/98rmPc0zn24a8Wplo/Sts4SrL3xZNATH5tWwNpPulBThPqnjdMU4Rw2Jf/mjlQXiT7+w3w60/HrMd62J/d/dyYrIuvuog3OAEi1vsiKCRm/9ptpbNA4E34ZUBSOpT3bx0b4NszYB2g7VdcmgHHXSY16AVCv3I3ZN0UmWphw1hpjpxfHTinE2pR5L0HVMikxqaxjCZI7DSpi8f4gQJn7gjLTh905o751Z3s7Y4L/v9NTEXmCPF425krwxDD4EMSMJ6BXgAExvPolWV0/W9HUtKX7XtEJUKWLUlikb7qTRWR1sld ubuntu@dev-01
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
  image: https://cloud.centos.org/centos/7/images/CentOS-7-aarch64-GenericCloud-2003.qcow2
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
  url: http://172.19.17.1:3478
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
        ssh_authorized_keys: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdXnRJVWf7OvFa0UZPkvDBave2BWhr29HFlO/bI/98rmPc0zn24a8Wplo/Sts4SrL3xZNATH5tWwNpPulBThPqnjdMU4Rw2Jf/mjlQXiT7+w3w60/HrMd62J/d/dyYrIuvuog3OAEi1vsiKCRm/9ptpbNA4E34ZUBSOpT3bx0b4NszYB2g7VdcmgHHXSY16AVCv3I3ZN0UmWphw1hpjpxfHTinE2pR5L0HVMikxqaxjCZI7DSpi8f4gQJn7gjLTh905o751Z3s7Y4L/v9NTEXmCPF425krwxDD4EMSMJ6BXgAExvPolWV0/W9HUtKX7XtEJUKWLUlikb7qTRWR1sld ubuntu@dev-01
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
