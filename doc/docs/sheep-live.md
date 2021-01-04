# Sheep-live

## What is sheep-live ?

Sheep-live is a Debian 10 Linux based on the GRML Live building system.
We use it to have a faster and optimized sheep execution.
It contains some packages absent in a basic grml and has a mechanism to download and run sheep via the information given in kernel command parameters while launching sheep-live.
As it, the user can simply have on his main server the sheep configuration file and the pxeboot file specifying in the kernel parameters to launch the service sheep when booting on sheep-live.

## Why sheep-live ?

Sheep could be run from any Linux distribution as soon as all the dependencies are present.
Providing a specific distribution gives two major advantages to avoid undesirable side effects :

* Linux environment to run Sheep with all the needed material for Sheep inside (avoid internet interaction during the Sheep process)
* A distribution used to test and validate sheep in the continuous integration platform

## How to create a sheep-live build ?

All the documentation related to this question is available in the git repository [sheep-live](https://github.com/sheeplinux/sheep-live)

## How to launch sheep-live

To launch sheep-live, place the sheep-live squashfs in your web server, the initrd and the kernel file in your HTTP / TFTP server.
Create a network boot file specifying the path to sheep-live squashfs.
If you want sheep to be run automatically after the operating system boot, specify it in the kernel command line with `startup=/usr/bin/sheep-service`.
Below is an example of a pxelinux file we use to launch sheep on our machines :

```
DEFAULT sheeplive

label sheeplive
    kernel /sheep-live/vmlinuz
    append boot=live fetch=http://server_add/sheep-live.squashfs initrd=/sheep-live/initrd.img ssh=sheep console=ttyS1,57600n8  sheep.script=http://server_add/sheep.sh sheep.config=http://server_add/sheepCfg.yml startup=/usr/bin/sheep-service

```
With `server_add` the address of the network interface connected to the machine we want to install.
As shown above, [GRML kernel parameters](https://git.grml.org/?p=grml-live.git;a=blob_plain;f=templates/GRML/grml-cheatcodes.txt;hb=HEAD) can be used to tune your configuration.
Here are the Sheep specific kernel parameters to automatically run Sheep when Sheep Live is booted:

* `sheep.script=http://...` : URL to download Sheep script from.
* `sheep.config=http://...` : URL to download the Sheep YAML configuration for your machine.
* `startup=/usr/bin/sheep-service` : Give script path to automatically start the Sheep service on boot (automatically install linux on your drive).
Without the `startup` parameter you'll have to log into Sheep Live to run the Sheep service
```
$ sheep-service

```
* `sheep.log.level` : Configure the logger with value `error` `warning` `info` or `debug`.
* `sheep.delay` : Delay in seconds to delay sheep-service execution. Can be useful to avoid having boot log in sheep log.
