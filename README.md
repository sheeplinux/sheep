# Sheep

[![Build Status](https://api.travis-ci.org/sheeplinux/sheep.svg?branch=master)](https://travis-ci.org/sheeplinux/sheep)

*Install any Linux distribution in seconds with Sheep*

![](img/sheep-logo.png)

The aim of Sheep is to provide tooling to install any Linux distribution from a running Linux operating system in an automated way implementing a standard process. It also provide good efficiency in term of execution time.

## Motivation

Installing a Linux distribution in an automated way has been a concern for system administrators for a long time. Of course, distribution vendors themselves provide mechanism to run their own installers in an automated way. The thing is, every single distribution comes with its own installation process and its own tools. Sheep proposes to uniform the installation process to easily install any Linux system whatever the distribution is.

Tools provided by distribution vendors are powerful and highly configurable. However, they come with some important downsides :

* Configuration mechanisms and tools are specific to each distribution (or at least specific to the distribution family)
* Creating configuration is painful beacuse of file format constraints and the amount of possible configurations
* The installation process is quite long
* Installing a distribution offline - without relying on an internet connection - requires additionnal work (e.g. setup a local distribution package repository)

Sheep goal is to get rid of all those painpoints. Looking at how Linux works and what are the necessary efforts to install it on a drive, it appears that it is quite easy to describe a process that is always
the regardless the distribution. See [Internals Section](internals.md) to get more details about this
process. The main idea of Sheep is to avoid using vendor installer programs and execute instead necessary steps to install the Linux operating system starting from a filesystem image.

A central concept in Sheep is to install Linux starting from a cloud image. Today, most of the distribution
vendors are publishing cloud images in various formats for the most popular cloud platforms. Sheep focuses
on `qcow2` images. As this is a widespread open format, it's provided by all vendors. That said, Sheep is able to handle compressed `tar` archives for the root filesystem which can be very useful in many situations.

To summarize, here are the advantages of Sheep over the standard vendors installers :

* Sheep is very easy to use with a minimal configuration
* Sheep is able to install any Linux distribution
* Using official cloud images from vendors makes easy to find images for Sheep
* Execution time is really fast. In the most advantageous situation, Sheep installs Linux in about 30 seconds

Lastly, as any solution, Sheep comes with a couple of drawbacks. Sheep does not offer as much options as the
vendors installers. That said, Sheep source code is quite simple and easy to customize.

Don't hesitate to open issues to ask for help or request features.

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

## License

```text
Copyright 2020 Mathilde Hermet
Copyright 2020 Guillaume Giamarchi

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
