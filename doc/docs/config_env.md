# Environment

## Simplified mode

Configure your future OS environment.
This has to be done this way when cloud-init is `disable`. Otherwise this part won't be taken into account.
This configuration will be turned into cloud-init user-data & meta-data files by sheep during execution.

* `users` : List users you want to create giving at least the `name`
  * `name` : User name
  * `sudoer` : Add this user to sudoer
     **NB : It will be created as a no password sudoer**
  * `password` : User password
  * `ssh_authorized_key` : Machine public key from where you want to access this server
  * `shell` : User type of shell
* `local_hostname` : Machine hostname

```yaml
environment:
  users:
    - name: linux
      sudoer: true
      password: linux
      ssh_authorized_key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdXnRJVWf7OvFa0UZPkvDBave2BWhr29HFlO/bI/98rmPc0zn24a8Wplo/Sts4SrL3xZNATH5tWwNpPulBThPqnjdMU4Rw2Jf/mjlQXiT7+w3w60/HrMd62J/d/dyYrIuvuog3OAEi1vsiKCRm/9ptpbNA4E34ZUBSOpT3bx0b4NszYB2g7VdcmgHHXSY16AVCv3I3ZN0UmWphw1hpjpxfHTinE2pR5L0HVMikxqaxjCZI7DSpi8f4gQJn7gjLTh905o751Z3s7Y4L/v9NTEXmCPF425krwxDD4EMSMJ6BXgAExvPolWV0/W9HUtKX7XtEJUKWLUlikb7qTRWR1sld ubuntu@dev-01
      shell: bash
  local_hostname: sheep

```

!!! Note

    If this section is left empty:

    * User **linux** with password **linux** will be given.
    * Machine hostname will be **sheep**.

## Advanced mode (cloud-init)

We can use more features enabled by cloud-init to set up the OS environment.
Configuring the envrionment with cloud-init is done through meta-data and user-data files.
The name of these files are the same than in `cloudInit` sheep section `userData` and `metaData`.

Refer to [cloud-init documentation](https://cloudinit.readthedocs.io/en/latest/#) for more details about syntax and options.

```yaml
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

```

!!! Note
    
    * See meta-data part  in cloud-init documentation : [meta-data](https://cloudinit.readthedocs.io/en/latest/topics/instancedata.html)
    * See user-data part in cloud-init documentation : [user-data](https://cloudinit.readthedocs.io/en/latest/topics/format.html)
