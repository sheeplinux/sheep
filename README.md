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
