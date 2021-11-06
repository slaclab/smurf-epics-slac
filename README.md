# SLAC's EPICS building RHEL6/CentOS 6 environment Docker image

## Description

This is a Docker image builder. The final result of the script build_docker.sh is an image containing the SLAC's EPICS environment needed to build EPICS IOCs in RHEL6 or CentOS 6, including EPICS base, modules, packages, and environment variables. The builder can work with only one EPICS base version of choice, but it can contain multiple versions of the same module and package.

You must run build_docker.sh in a machine with Docker installed and with SLAC's AFS mounted. The script brings base, modules, and packages from the AFS and, so, it depends on it.

Two files must be provided as inputs for the script:
- packages: list of packages containing the path, package name, and version. The list items can take any order. You can check configure/CONFIG_SITE of the IOC application that you want to build inside the container to get the list elements. Examples:
  - boost/1.63.0
  - cpsw/framework/R3.6.3
- epics-modules: contains the EPICS base version on the first line and the modules slash version on the next lines. The easiest way of obtaining this list is going to the top directory of the IOC that you want to build inside the container and using the eco tools command epics-versions. The formatted output by epics-versions is compatible with what build_docker.sh is expecting. Make sure that you have the environment set to use eco tools. epics-versions print the modules in alphabetic order, so a manual tweak is needed. You must order the list in dependency order. The modules will be built in the same order as this list and so, if a module depends on another, it expects that the other module is already available. Example:
   -   epics/iocTop/gmd/R2.1.0             base/R7.0.3.1-1.0
   -   seq                 seq/R2.2.4-1.2
   -   asyn                asyn/R4.32-1.0.0
   -   autosave            autosave/R5.8-2.1.0

This repository provides two examples of epics-modules/packages pair of files. One with EPICS 3.15 for IOCs used in SMuRF and another for EPICS 7 with a much more complex scenario, containing 21 modules. The latter is based on support for the IOC application used with the ATCA-based common platform.

You can use both example files to check one possible dependency order for the modules to build correctly.

## Building the image

The provided script *build_docker.sh* will automatically build the docker image, provided that the files epics-modules and packages are available. Notice that no Dockerfile is provided by this repository as it will be created automatically.

The script needs a name for the image. This name will be referred to as <image_name> in the remainder of this document. The image name can be any valid Docker image tag. Examples: my_image, or my_organization/my_image, or my_organization/my_image:version.

The script copies the already built packages from AFS to a temp_files directory. It also clones the GIT repositories available in AFS to specific versions of the modules and base. The clones are placed in temp_files, too. Docker has a security feature that forbids it to read files in directories above the current one. Neither symbolic links are accepted. So, we need to copy locally everything that we want to place inside the container.

With the files available locally and the Dockerfile generated, the image will be built by copying the packages inside the container, building the EPICS base, and building all the modules.

After the completion, you have a ready-to-use CentOS 6 container to build and test your IOC application.

## Cleaning and uninstalling
You can use two optional arguments to clean your intermediary and final products:
- -c or --clean: delete all modules, packages, EPICS base that were copied from AFS. It also deletes the file Dockerfile_temp.
- -u or --uninstall: delete Dockerfile and the Docker image.

## Using this image

The generated image is intended to be used as a test container for IOC applications or as a base to build another docker image. 

A suggested approach to work with an IOC application is to have it in a directory outside the container. The container would have a bound directory to access the IOC application. You could edit files directly from the host computer or from inside the container, but you would have to run *make* from inside the container. Remember that everything that changed inside the container, except for the binded directories will be lost once you exit it. So, only change what you want to be persisted in a bound directory.

Suppose that you have your IOC application in the directory /home/myname/my_ioc_application outside the container. You want it to bind to the directory /usr/local/src/epics/iocTop/. This is the command that you would use to access the container and work with your IOC application:

```
docker run -ti --rm --name my_container --network=host --mount type=bind,source=/home/myname/my_ioc_application,target=/usr/local/src/epics/iocTop/ <image_name> bash
```

You will have to decide whether you want the $IOC_DATA area bound or not. If you want to persist this information and have it outside the container, you have to add a new bind to the command above. Otherwise, just define an arbitrary location for $IOC_DATA.

To access PVs from outside the host (example lcls-dev3), define EPICS_CA_ADDR_LIST to the host IP, not the broadcast to the host network. Host here is the machine running the Docker container.

For using the image as a base to build another one, start the new docker image Dockerfile with this line:

```
ROM <docker_hub_image>:<VERSION>
```

Where:
- **\<VERSION\>**: is the tagged version of the container you want to run. 
