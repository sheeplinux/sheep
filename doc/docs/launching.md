# Sheep launching 

## Launch sheep using sheep-live

This first way to launch sheep makes the process run fully automated.
It is documented in [sheep-live documentation](./sheep-live.md)

## Execution without kernel parameters command line

Reading variables through /proc/cmdline is good for deployment automation,
especially when booting a live distribution from the network as an installation
environment.

However, we are able to run Sheep passing parameters directly
to the script because there are no reason to enforce this way of doing. We are
be able to pass parameters even if it was not previoulsy configured in the
kernel parameter line.

It's also usefull for testing purpose during development because we can run
different tests without the need of rebooting the machine.

See the example below :

```bash
SHEEP_PARAMETERS='sheep.config=http://netserver/ubuntu-16.04-leopard-sheep-cfg.yml' sheep
```
