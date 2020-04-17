## Basic network configuration

Configure OS Network has to be done this way when cloud-init is `disable`. Otherwise this part won't be taken into account.   
This configuration will be turned into a cloud-init network configuration file by sheep during execution.

* `interfaces` : List of interfaces to configure
 * `id` : Interface identifier
 * `type` : **static** or **dhcp**
 * `address` : Required in **static** mode
 * `gateway` : Can be configured in **static** mode

```yaml
network:
  interfaces:
    - id: ens1
      type: static
      address: 172.19.17.111
      gateway: 172.19.17.1

```

!!! Note
    
    If this section empty, the network will be configures by clou-init default mode
    That means **dhcp** on the first connected interface.

## Advanced network configuration with cloud-init usage

Configure network in sheep-configuration file the same way you would writethe file network-config for cloud-init.   
This permit you to use all cloud-init features not adapted by sheep.   
Set `.cloudInit.enabled` on `true` to see that taken into account.
See network part on cloud-init documentation : [network-config](https://cloudinit.readthedocs.io/en/latest/topics/network-config.html)
