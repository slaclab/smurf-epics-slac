FROM centos:6.10

#curl sets up the correct website for yum -y update
RUN curl https://www.getpagespeed.com/files/centos6-eol.repo --output /etc/yum.repos.d/CentOS-Base.repo

# Install packages
RUN yum -y update && yum install -y wget gcc gcc-c++ readline-devel perl && yum clean all -y

# Add epel repo
# epel-release has been archived, new link
RUN wget https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -ivh epel-release-6-8.noarch.rpm
RUN rm -rf epel-release-6-8.noarch.rpm

# Install extra packages from epel
RUN yum install -y re2c && yum clean all -y

# Define some common global env vars
## EPICS base version
ENV EPICS_BASE_VERSION R3.15.5-1.0
## Host architecture
ENV EPICS_HOST_ARCH rhel6-x86_64
## Top directory for all EPICS related packages
ENV EPICS_SITE_TOP /usr/local/src/epics
## Top directory for base
ENV BASE_SITE_TOP ${EPICS_SITE_TOP}/base
## Directory of the EPICS base version we are using
ENV EPICS_BASE ${BASE_SITE_TOP}/${EPICS_BASE_VERSION}
## Top directory for modules
ENV EPICS_MODULES ${EPICS_SITE_TOP}/${EPICS_BASE_VERSION}/modules
## Top directory for IOCs
ENV IOC_SITE_TOP ${EPICS_SITE_TOP}/iocTop
## Top directory for packages
ENV PACKAGE_SITE_TOP /usr/local/src/packages
## EPICS CONFIGURATIONS
ENV EPICS_CA_REPEATER_PORT 5065
ENV EPICS_CA_AUTO_ADDR_LIST YES
ENV EPICS_CA_SERVER_PORT 5064
ENV IOC_DATA /data/epics/ioc/data

# Install packages
# (I'm copying the ones from AFS for now instead of recompile...)
WORKDIR ${PACKAGE_SITE_TOP}
ADD packages/boost/*.tar.gz             boost/
ADD packages/pcre/*.tar.gz              pcre
ADD packages/cpsw/framework/*.tar.gz    cpsw/framework/
RUN cd cpsw/framework/ && ln -s R3.6.4 R3.6.3
ADD packages/timing/bsa/*.tar.gz        timing/bsa/
ADD packages/timing/tpg/*.tar.gz        timing/tpg/
ADD packages/yaml-cpp/*.tar.gz          yaml-cpp/


# Install EPICS base
RUN mkdir -p ${BASE_SITE_TOP}
RUN mkdir -p ${IOC_DATA}
WORKDIR ${BASE_SITE_TOP}

ADD epics/base/${EPICS_BASE_VERSION}.tar.gz .
WORKDIR ${EPICS_BASE_VERSION}
# Build only for the host architecture
RUN sed -i -e 's/^CROSS_COMPILER_TARGET_ARCHS=.*/CROSS_COMPILER_TARGET_ARCHS=/g' configure/CONFIG_SITE
RUN make

ENV PATH ${PATH}:${EPICS_BASE}/bin/${EPICS_HOST_ARCH}
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:${EPICS_BASE}/lib/${EPICS_HOST_ARCH}

# Install EPICS modules
WORKDIR ${EPICS_MODULES}
ADD epics/modules/RELEASE_SITE .

## Seq
### R2.2.4-1.1
ARG SEQ_MODULE_VERSION=R2.2.4-1.1
WORKDIR ${EPICS_MODULES}
RUN mkdir seq
WORKDIR seq
ADD epics/modules/seq/${SEQ_MODULE_VERSION}.tar.gz .
WORKDIR ${SEQ_MODULE_VERSION}
# Point to the re2c install in the system
RUN sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE
RUN make
### R2.2.4-1.0
ARG SEQ_MODULE_VERSION=R2.2.4-1.0
WORKDIR ..
ADD epics/modules/seq/${SEQ_MODULE_VERSION}.tar.gz .
WORKDIR ${SEQ_MODULE_VERSION}
# Point to the re2c install in the system
RUN sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE
RUN make

## Asyn
### R4.31-0.1.0
ARG ASYN_MODULE_VERSION=R4.31-0.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir asyn
WORKDIR asyn
ADD epics/modules/asyn/${ASYN_MODULE_VERSION}.tar.gz .
WORKDIR ${ASYN_MODULE_VERSION}
RUN make

## Autosave
### R5.7.1-3.2.0
ARG AUTOSAVE_MODULE_VERSION=R5.7.1-3.2.0
WORKDIR ${EPICS_MODULES}
RUN mkdir autosave
WORKDIR autosave
ADD epics/modules/autosave/${AUTOSAVE_MODULE_VERSION}.tar.gz .
WORKDIR ${AUTOSAVE_MODULE_VERSION}
RUN make
### R5.8-1.0.0
ARG AUTOSAVE_MODULE_VERSION=R5.8-1.0.0
WORKDIR ..
ADD epics/modules/autosave/${AUTOSAVE_MODULE_VERSION}.tar.gz .
WORKDIR ${AUTOSAVE_MODULE_VERSION}
RUN make

## CaPutLog
ARG CAPUTLOG_MODULE_VERSION=R3.5-0.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir caPutLog
WORKDIR caPutLog
ADD epics/modules/caPutLog/${CAPUTLOG_MODULE_VERSION}.tar.gz .
WORKDIR ${CAPUTLOG_MODULE_VERSION}
RUN make

## IocAdmin
### R3.1.15-1.1.0
ARG IOCADMIN_MODULE_VERSION=R3.1.15-1.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir iocAdmin
WORKDIR iocAdmin
ADD epics/modules/iocAdmin/${IOCADMIN_MODULE_VERSION}.tar.gz .
WORKDIR ${IOCADMIN_MODULE_VERSION}
RUN make
### R3.1.15-1.0.0
ARG IOCADMIN_MODULE_VERSION=R3.1.15-1.0.0
WORKDIR ..
ADD epics/modules/iocAdmin/${IOCADMIN_MODULE_VERSION}.tar.gz .
WORKDIR ${IOCADMIN_MODULE_VERSION}
RUN make

## Calc
ARG CALC_MODULE_VERSION=R3.6.1-0.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir calc
WORKDIR calc
ADD epics/modules/calc/${CALC_MODULE_VERSION}.tar.gz .
WORKDIR ${CALC_MODULE_VERSION}
RUN make

## Sscan
ARG SSCAN_MODULE_VERSION=R2.10.2-0.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir sscan
WORKDIR sscan
ADD epics/modules/sscan/${SSCAN_MODULE_VERSION}.tar.gz .
WORKDIR ${SSCAN_MODULE_VERSION}
RUN make

## miscUtils
### R2.2.5
ARG MISCUTILS_MODULE_VERSION=R2.2.5
WORKDIR ${EPICS_MODULES}
RUN mkdir miscUtils
WORKDIR miscUtils
ADD epics/modules/miscUtils/${MISCUTILS_MODULE_VERSION}.tar.gz .
WORKDIR ${MISCUTILS_MODULE_VERSION}
RUN make

## yamlLoader
### R1.1.0
ARG YAMLLOADER_MODULE_VERSION=R1.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir yamlLoader
WORKDIR yamlLoader
ADD epics/modules/yamlLoader/${YAMLLOADER_MODULE_VERSION}.tar.gz .
WORKDIR ${YAMLLOADER_MODULE_VERSION}
RUN sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64
RUN sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE
RUN rm -rf rm configure/CONFIG_SITE.Common.linuxRT-x86_64
RUN make

## bsaDriver
### R1.5.0
ARG BSADRIVER_MODULE_VERSION=R1.5.0
WORKDIR ${EPICS_MODULES}
RUN mkdir bsaDriver
WORKDIR bsaDriver
ADD epics/modules/bsaDriver/${BSADRIVER_MODULE_VERSION}.tar.gz .
WORKDIR ${BSADRIVER_MODULE_VERSION}
RUN sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64
RUN sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE
RUN rm -rf rm configure/CONFIG_SITE.Common.linuxRT-x86_64
RUN make

## crossbarControl
### R1.0.4
ARG CROSSBARCONTROL_MODULE_VERSION=R1.0.4
WORKDIR ${EPICS_MODULES}
RUN mkdir crossbarControl
WORKDIR crossbarControl
ADD epics/modules/crossbarControl/${CROSSBARCONTROL_MODULE_VERSION}.tar.gz .
WORKDIR ${CROSSBARCONTROL_MODULE_VERSION}
RUN sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64
RUN sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE
RUN rm -rf rm configure/CONFIG_SITE.Common.linuxRT-x86_64
RUN make

## pvDataCPP
ARG pvDataCPP_MODULE_VERSION=R7.0.0-0.0.1
WORKDIR ${EPICS_MODULES}
RUN mkdir pvDataCPP
WORKDIR pvDataCPP
ADD epics/modules/pvDataCPP//${pvDataCPP_MODULE_VERSION}.tar.gz .
WORKDIR ${pvDataCPP_MODULE_VERSION}
RUN make

# pvAccessCPP
ARG pvAccessCPP_MODULE_VERSION=R6.0.0-0.3.0
WORKDIR ${EPICS_MODULES}
RUN mkdir pvAccessCPP
WORKDIR pvAccessCPP
ADD epics/modules/pvAccessCPP/${pvAccessCPP_MODULE_VERSION}.tar.gz .
WORKDIR ${pvAccessCPP_MODULE_VERSION}
RUN make

## pvDatabaseCPP
ARG pvDatabaseCPP_MODULE_VERSION=R4.3.0-0.0.3
WORKDIR ${EPICS_MODULES}
RUN mkdir pvDatabaseCPP
WORKDIR pvDatabaseCPP
ADD epics/modules/pvDatabaseCPP/${pvDatabaseCPP_MODULE_VERSION}.tar.gz .
WORKDIR ${pvDatabaseCPP_MODULE_VERSION}
RUN make

## pva2pva
ARG pva2pva_MODULE_VERSION=R1.0.0-0.3.1
WORKDIR ${EPICS_MODULES}
RUN mkdir pva2pva
WORKDIR pva2pva
ADD epics/modules/pva2pva/${pva2pva_MODULE_VERSION}.tar.gz .
WORKDIR ${pva2pva_MODULE_VERSION}
RUN make

## normativeTypesCPP
ARG normativeTypesCPP_MODULE_VERSION=R5.2.0-0.0.1
WORKDIR ${EPICS_MODULES}
RUN mkdir normativeTypesCPP
WORKDIR normativeTypesCPP
ADD epics/modules/normativeTypesCPP/${normativeTypesCPP_MODULE_VERSION}.tar.gz .
WORKDIR ${normativeTypesCPP_MODULE_VERSION}
RUN make
