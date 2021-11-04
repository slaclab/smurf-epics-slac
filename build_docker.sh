#!/usr/bin/env bash

temp_docker_file=Dockerfile_temp
release_site_template=RELEASE_SITE.template
temp_files_dir=temp_files
git_repos=/afs/slac/g/cd/swe/git/repos/package/epics
package_area=/afs/slac/g/lcls/package

# $1 is the EPICS base version
function base_version_in_files() {
    sed -i -e "s/*TAG_BASE_VERSION/$1/g" $temp_docker_file
    cp -f $release_site_template $temp_files_dir/modules/RELEASE_SITE
    sed -i -e "s/*TAG_BASE_VERSION/$1/g" $temp_files_dir/modules/RELEASE_SITE
}

# $1 is the EPICS base version to bring
function bring_epics_base() {
    mkdir -p $temp_files_dir/base
    # Remove last portion of the version number and replace with the string
    # 'branch'. We are cloning the branch HEAD instead of a tag.
    base_branch=${base_version%?}branch
    git clone --branch $base_branch $git_repos/base/base.git $temp_files_dir/base/$1
    base_version_in_files $1
}

# $1 is the module name.
# $2 is the module version.
function add_module_to_dockerfile() {
    echo >> $temp_docker_file
    echo "## " $1 >> $temp_docker_file 
    echo "### " $2 >> $temp_docker_file
    echo ARG ${1^^}_MODULE_VERSION=$2 >> $temp_docker_file
    echo WORKDIR \${EPICS_MODULES} >> $temp_docker_file
    echo RUN mkdir -p $1/\${${1^^}_MODULE_VERSION} >> $temp_docker_file
    echo WORKDIR $1/\${${1^^}_MODULE_VERSION} >> $temp_docker_file
    echo COPY $temp_files_dir/modules/$1/\${${1^^}_MODULE_VERSION} . >> $temp_docker_file
    echo "#" Point to the re2c install in the system >> $temp_docker_file
    echo RUN if [ -f configure/CONFIG_SITE ]";" then sed -i -e "'s|^RE2C =.*|RE2C = /usr/bin/re2c|g'" configure/CONFIG_SITE";" fi"; \\" >> $temp_docker_file
    echo "#" Remove cross compilation >> $temp_docker_file
    echo "    "if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]";" then sed -i -e "'s|^PACKAGE_AREA=.*|PACKAGE_AREA=\${PACKAGE_SITE_TOP}|g'" configure/CONFIG_SITE.Common.rhel6-x86_64";" fi"; \\" >> $temp_docker_file
    echo "    "if [ -f configure/CONFIG_SITE ]";" then sed -i -e "'s|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g'" configure/CONFIG_SITE";" fi"; \\" >> $temp_docker_file
    echo "    "rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64"; \\" >> $temp_docker_file
    echo "    "make >> $temp_docker_file
}

# $1 is the module name.
# $2 is the module version.
function bring_module() {
    mkdir $temp_files_dir/modules/$1
    git clone --branch $2 $git_repos/modules/$1.git $temp_files_dir/modules/$1/$2
    add_module_to_dockerfile $1 $2
}

function bring_epics() {
    mkdir -p $temp_files_dir/modules
    filename='epics-modules'

    # Reading each line with modules versions.
    while read line; do
	# Read last string after space. It must be in the format
	# <module name>/<version>
        version=${line##* }

	# Separates the module name from the version in an array
        tuplet=(${version//// })

	if [ ${tuplet[0]} == 'base' ]; then
            base_version=${tuplet[1]}

            # Bring EPICS base from AFS Git
	    bring_epics_base $base_version
	else
	    # Bring the module from AFS Git
	    bring_module ${tuplet[0]} ${tuplet[1]}
	fi
    done < $filename
}

function bring_packages() {
    filename='packages'

    # Reading each line with package versions.
    while read line; do
	echo Copying $line
	mkdir -p $temp_files_dir/packages/$line
	cp -Rn $package_area/$line/rhel6-x86_64 $temp_files_dir/packages/$line
    done < $filename
}

cp -f Dockerfile_base $temp_docker_file
bring_packages
bring_epics
cp -f $temp_docker_file Dockerfile

# Definitions
#repo=smurf-epics-slac
#org=jesusvasquez333

# Use the git tag to tag the docker image
#tag=$(git describe --tags --always)

# Build the docker and tagged it with the application version
#docker build -t ${org}/${repo} .
#docker tag ${org}/${repo} ${org}/${repo}:${tag}
#printf "Docker image created: ${org}/${repo}:${tag}\n"
