# SLAC's EPICS building environment Docker image for the SMuRF project

## Description

This docker image, named **smurf-epics-slac** contains the SLAC's EPICS environment needed to build EPICS IOCs used in the SMuRF project.

It is based on centos 6.10 to match closely the development environment at SLAC, and contains:
- EPICS base, version R3.15.5-1.0
- EPICS modules:
  - asyn, version R4.31-0.1.0
  - autosave, versions R5.7.1-3.2.0 and R5.8-1.0.0
  - bsaDriver, versions R1.0.4 and R1.5.0
  - caPutLog, version R3.5-0.1.0
  - calc, version R3.6.1-0.1.0
  - crossbarControl, version R1.0.4
  - iocAdmin, versions R3.1.15-1.0.0 and R3.1.15-1.1.0
  - miscUtils, version R2.2.5
  - normativeTypesCPP, version R5.2.0-0.0.1
  - pvAccessCPP, version R6.0.0-0.3.0
  - pvDataCPP, version R7.0.0-0.0.1
  - pvDatabaseCPP, version R4.3.0-0.0.3
  - pva2pva, version R1.0.0-0.3.1
  - seq, versions R2.2.4-1.0 and R2.2.4-1.1
  - sscan, version R2.10.2-0.1.0
  - yamlLoader, version R1.1.0
- Packages:
  - boost, version 1.63.0
  - cpsw framework, version R3.6.4 and R3.6.3
  - pcre, version 8.37
  - timing bsa, versions R1.1.0 and R1.1.1
  - timinig tpg, version R1.3.2
  - yaml-cpp, version 0.5.3

## Source code

The source code was manually checkout from SLAC's git repositories hosted in an AFS-based internal git repositories. Each individual packages was compress into a **tar.gz** file and placed alongside the Dockerfile in the following directory tree:

```
── epics/
│   ├── base/
│   │   └── R3.15.5-1.0.tar.gz
│   └── modules/
│       ├── asyn/
│       │   └── R4.31-0.1.0.tar.gz
│       ├── autosave/
│       │   ├── R5.7.1-3.2.0.tar.gz
│       │   └── R5.8-1.0.0.tar.gz
│       ├── bsaDriver/
│       │   ├── R1.0.4.tar.gz
│       │   └── R1.5.0.tar.gz
│       ├── caPutLog/
│       │   └── R3.5-0.1.0.tar.gz
│       ├── calc/
│       │   └── R3.6.1-0.1.0.tar.gz
│       ├── crossbarControl/
│       │   └── R1.0.4.tar.gz
│       ├── iocAdmin/
│       │   ├── R3.1.15-1.0.0.tar.gz
│       │   └── R3.1.15-1.1.0.tar.gz
│       ├── miscUtils/
│       │   └── R2.2.5.tar.gz
│       ├── normativeTypesCPP/
│       │   └── R5.2.0-0.0.1.tar.gz
│       ├── pvAccessCPP/
│       │   └── R6.0.0-0.3.0.tar.gz
│       ├── pvDataCPP/
│       │   └── R7.0.0-0.0.1.tar.gz
│       ├── pvDatabaseCPP/
│       │   └── R4.3.0-0.0.3.tar.gz
│       ├── pva2pva/
│       │   └── R1.0.0-0.3.1.tar.gz
│       ├── seq/
│       │   ├── R2.2.4-1.0.tar.gz
│       │   └── R2.2.4-1.1.tar.gz
│       ├── sscan/
│       │   └── R2.10.2-0.1.0.tar.gz
│       ├── yamlLoader/
│       │   └── R1.1.0.tar.gz
├── packages/
│   ├── boost/
│   │   └── 1.63.0.tar.gz
│   ├── cpsw/
│   │   └── framework/
│   │       └── R3.6.4.tar.gz
│   ├── pcre/
│   │   └── 8.37.tar.gz
│   ├── timing/
│   │   ├── bsa/
│   │   │   ├── R1.1.0.tar.gz
│   │   │   └── R1.1.1.tar.gz
│   │   └── tpg/
│   │       └── R1.3.2.tar.gz
│   └── yaml-cpp/
│       └── yaml-cpp-0.5.3.tar.gz
```

In each directory, the corresponding package version is place compressed in a file named `<VERSION>.tar.gz`

## Building the image

The provided script *build_docker.sh* will automatically build the docker image. It will tag the resulting image using the same git tag string (as returned by `git describe --tags --always`).

## Using this image

This image is intended to be used as a base to build other docker image. In order to do so, start the new docker image Dockerfile with this line:

```
ROM jesusvasquez333/smurf-epics-slac:<VERSION>
```

A container however can be run as well from this image. For example, you can start the container in the foreground with this command

```
docker run -ti --rm --name smurf-epics-slac jesusvasquez333/smurf-epics-slac:<VERSION>
```

Where:
- **<VERSION>**: is the tagged version of the container your want to run. 
