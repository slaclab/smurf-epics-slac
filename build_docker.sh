#!/usr/bin/env bash

show_usage() {
    echo ""
    echo "Usage: $0 [-hcu] image_name"
    echo ""
    echo "Builds a CentOS 6 Docker image named as image_name containing EPICS"
    echo "base and modules listed in a required 'epics-modules' file and also"
    echo "packages listed in a required 'packages' file."
    echo ""
    echo "The image name can be any valid Docker image tag. Examples: my_image,"
    echo "or my_organization/my_image, or my_organization/my_image:version."
    echo ""
    echo "Optional arguments:"
    echo "  -h, --help                  Show this help message and exit"
    echo "  -c, --clean                 Remove all modules, base, and package files inside the temp_files directory as well as the Dockerfile_temp file"
    echo "  -u, --uninstall             Delete the Dockerfile file and the generated Docker image."
    echo ""
    exit
}

function clean_files() {
    rm -rf temp_files
    rm -f Dockerfile_temp
}

function uninstall() {
    rm -f Dockerfile
    docker rmi "$1"
}

temp_docker_file=Dockerfile_temp
release_site_template=RELEASE_SITE.template
temp_files_dir=temp_files
git_repos=/afs/slac/g/cd/swe/git/repos/package/epics
package_area=/afs/slac/g/lcls/package
uninstall=0
clean=0
docker_image_name=""

if [ $# -eq 0 ]; then
    echo "The name of the Docker image must be provided."
    show_usage
fi

while [ -n "$1" ]; do
    case "$1" in
        -h | --help)
            # Show this help message and exit
            show_usage
            exit
            ;;
        -c | --clean)
            # Remove temporary files
	    clean=1
            ;;
        -u | --uninstall)
	    # Delete Dockerfile and Docker image
	    uninstall=1
            ;;
        *)
            # Extra argument should be the Docker image name
	    if [ -z "$docker_image_name" ]; then
                docker_image_name=$1
	    else
		# If image name was provided before, what is this extra argument?
                echo "Invalid argument $1"
		show_usage
		exit
	    fi
    esac
    shift
done

# User wants only to clean, so we don't need the image name
if [ $clean -eq 1 -a $uninstall -eq 0 ]; then
    clean_files
    exit
fi

# For all other cases, image name is required
if [ -z "$docker_image_name" ]; then
    echo "The name of the Docker image must be provided."
    show_usage
    exit
fi

if [ $clean -eq 1 ]; then
    clean_files
fi

if [ $uninstall -eq 1 ]; then
    uninstall $docker_image_name
fi

# Exit if using clean or uninstall
if [ $clean -eq 1 -o $uninstall -eq 1 ]; then
    exit
fi

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
docker build -t $docker_image_name .
