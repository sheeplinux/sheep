# Sheep

*Install any Linux distribution in seconds with Sheep*

![](img/sheep-logo.png)

The aim of this project is to provide a tool to install any Linux distribution from a running Linux operating system in an automated way implementing a standard process. It also provide good efficiency in term of execution time.

Usually, every single distribution comes with its own installation process and its own tools for installation automation. Here, we propose an installation process that will be always the same whatever your distribution is. In some cases, the tool
implements some speficities depending on the operating system but it is totally transparent for the end user.

## How it works?

The main idea of Sheep is to avoid using vendor installer programs and execute instead necessary steps to install the Linux operating system starting from a filesystem image.

## Supported Linux distributions

Sheep provide a process able to install any Linux operating system. However, Sheep uses cloud-init to configuration the operating system.

Sheep have been successfully tested with the following distributions

- Ubuntu 16.04
- Ubuntu 18.04
- CentOS 7
- Debian 9
- Fedora 28
- Fedora 29
- Fedora 30
- OpenSuse Leap 15.0
- OpenSuse Leap 15.1
