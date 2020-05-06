# About

## Sheep Configuration File

The configuration file is in yaml.   
If it isn't included in the sheep-live OS after a build, it will be downloaded by the program if you give the path to the file in the kernel parameters to boot sheep-live.

As we decided to rely on cloud-init to configure the environment, there are two ways to write sheep configuration file: one is for users who want to setup the environment of the OS without any knowledge about cloud-init, and the second one is for users who know how to use cloud-init in NoCloud mode and want to have access to all cloud-init features via the sheep configuration file.
