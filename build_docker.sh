#!/usr/bin/env bash

# $1 is the EPICS base version to bring
function bring_epics_base() {
    mkdir -p epics/base
    # Remove last portion of the version number and replace with the string
    # 'branch'. We are cloning the branch HEAD instead of a tag.
    base_branch=${base_version%?}branch
    git clone --branch $base_branch /afs/slac/g/cd/swe/git/repos/package/epics/base/base.git epics/base/$1
}

# $1 is the module name.
# $2 is the module version.
function bring_module() {
    mkdir epics/modules/$1
    git clone --branch $2 /afs/slac/g/cd/swe/git/repos/package/epics/modules/$1.git epics/modules/$1/$2
}

function bring_epics() {
    mkdir -p epics/modules
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

bring_epics

# Definitions
#repo=smurf-epics-slac
#org=jesusvasquez333

# Use the git tag to tag the docker image
#tag=$(git describe --tags --always)

# Build the docker and tagged it with the application version
#docker build -t ${org}/${repo} .
#docker tag ${org}/${repo} ${org}/${repo}:${tag}
#printf "Docker image created: ${org}/${repo}:${tag}\n"
