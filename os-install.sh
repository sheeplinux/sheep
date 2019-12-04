#!/bin/bash

set -e

#
# Shortcut for log_info function
#
# $* - Text to log
#
log() {
    log_info $*
}

#
# Log text in file specified by the environment variable
# OS_INSTALL_LOG_FILE when log level level is ERROR or INFO
#
# $* - Text to log
#
log_info() {
    _log INFO $*
}

#
# Log text in file specified by the environment variable
# OS_INSTALL_LOG_FILE when log level level is ERROR or INFO
#
# $* - Text to log
#
log_warning() {
    _log WARNING $*
}

#
# Log text in file specified by the environment variable
# OS_INSTALL_LOG_FILE (always)
#
# $* - Text to log
#
log_error() {
    _log ERROR $*
}

#
# Log text in file specified by the environment variable
# OS_INSTALL_LOG_FILE when log level level is DEBUG
#
# $* - Text to log
#
log_debug() {
    _log DEBUG $*
}

#
# Internal function for logging. The one that actually do logging
#
# $1 - Log severity (i.e. ERROR, WARNING, INFO or DEBUG)
# $* - Text to log
#
_log() {
    #
    # Log file to log into
    #
    if [ -z "${OS_INSTALL_LOG_FILE}" ] ; then
        OS_INSTALL_LOG_FILE="/tmp/os-install-$(date +%s).log"
    fi
    touch ${OS_INSTALL_LOG_FILE}

    #
    # Authorized log level are ERROR, WARNING, INFO and DEBUG
    #
    if [ -z "${OS_INSTALL_LOG_LEVEL}" ] ; then
        OS_INSTALL_LOG_LEVEL=INFO
    fi

    local severity="${1}"

    if [ "${severity}" = 'ERROR' ] ; then
        :
    elif [ "${severity}" = 'WARNING' ] ; then
        if [[ "${OS_INSTALL_LOG_LEVEL}" = "ERROR" ]] ; then
            return
        fi
    elif [ "${severity}" = 'DEBUG' ] ; then
        if [ "${OS_INSTALL_LOG_LEVEL}" != "DEBUG" ] ; then
            return
        fi
    else
        #
        # If severity is equals to something else, the only one remaining authorized value is 'INFO',
        # so we force this value. It is equivalent to have a fallback value to INFO when the value is unknown
        #
        severity=INFO
        if [[ "${OS_INSTALL_LOG_LEVEL}" = "ERROR" || "${OS_INSTALL_LOG_LEVEL}" = "WARNING" ]] ; then
            return
        fi
    fi

    {
        printf "$(date '+[%D %T %z]') %-7s | " ${severity}
        shift
        echo "$*"
    } >> $OS_INSTALL_LOG_FILE
}

#
# $1 - Error message
#
exit_on_error() {
    log_debug "-> ${FUNCNAME[0]} $*"

    echo "ERROR : $1" >&2
    log "Exit with status code 1"
    exit 1
}

#
# Configuration map populated when search_value is called the first time.
#
declare -A configMap

#
# search_value returns the value matching a given parameter identifier.
# if the parameter is not defined or if its value is blank, it returns
# a default value if provided.
#
# When the function is called the first it populate the `configMap``
# variable parsing the commande line parameter.
#
# By default, parameters are retrieved from the kernel command line
# reading /proc/cmdline content. This can be overriden by setting up
# the OS_DEPLOY_PARAMETERS environment variable with the exact same
# syntax.
#
# $1 - Parameter identifier
# $2 - Default value
#
search_value() {
    log_debug "-> ${FUNCNAME[0]} $*"

    if [ ${#configMap[@]} -eq 0 ] ; then
		local cmd=$(cat /proc/cmdline)

		IFS=' ' read -r -a array <<< "${cmd}"
		for param in ${array[@]} ; do
			local key=$(echo "${param}" | cut -d '=' -f 1)
			local value=$(echo "${param}" | cut -d '=' -f 2-)
			configMap[${key}]=${value}
		done
    fi
	if [ "${1}" == "deployConfig" ] || [ "${1}" == "deployOS" ] ; then
		local value=${configMap[${1}]}
    else
		local value=$(yq -r $1 ${CONFIG_FILE})
		if [ ${value} == "null" ] ; then
			value=""
		fi
	fi
    echo ${value:-${2}}
}

#
# $1 - key
# $2 - error message if the value is not found
#
search_mandatory_value() {
    log_debug "-> ${FUNCNAME[0]} $*"

    local value=$(yq -r $1 ${CONFIG_FILE})

    [ "${value}" == "null" ] && exit_on_error "$2"
    log "Mandatory value for '$1' found => '${value}'"
    echo "${value}"
}

#
# This function prepare the environment by downloading tools required by the code for installation, parser yaml for variables implementation
#
prepare_env() {
    log_debug "-> ${FUNCNAME[0]} $*"

    ### Workaround for Debian repos issue when runnning GRML
    ###     E: The repository 'http://security.debian.org testing/updates Release' does not have a Release file.
    ### We don't need this package repository so we delete it
    cat <<- 'EOF' > /etc/apt/sources.list.d/debian.list
        deb     http://snapshot.debian.org/archive/debian/20181230/ testing main contrib non-free
        deb-src http://snapshot.debian.org/archive/debian/20181230/ testing main contrib non-free
		EOF

    # Downloading of paquet needed to parse YAML configuration file
    apt update
    log_debug "apt-update return : $?"
    apt install -y python-pip
    log_debug "apt install python-pip return : $?"
    apt install -y python-setuptools
    log_debug "apt install python-setuptools return : $?"
    pip install wheel
    log_debug "apt install wheel return : $?"
    apt install -y jq
    log_debug "apt install jq return : $?"
    pip install yq
    log_debug "apt install yq return : $?"
}

load_config() {
    log_debug "-> ${FUNCNAME[0]} $*"

    local CONFIG_FILE_PATH=$(search_value  deployConfig)
    if [ -z ${CONFIG_FILE_PATH} ] ; then
        exit_on_error "Configuration file is missing"
    fi
    CONFIG_FILE=$(mktemp -d)/config
    wget --quiet -O ${CONFIG_FILE} ${CONFIG_FILE_PATH}
    log_debug "downloading of config file by wget return : $?"
}
#
#Create every variable needed by calling search_value or search_mandatory_value
#
config_variable() {
    log_debug "-> ${FUNCNAME[0]} $*"

    OS_NAME=$(search_value ".linux.label" "linux")
    BOOT_SERVER=$(search_value ".network.ipAdr_serverPxe")
    PUBLIC_IFACE_NAME=$(search_mandatory_value ".network.interface" "'intName' parameter must be provided")
    local ret=$?
    if [ ${ret} -ne 0 ] ; then
		exit ${ret}
    fi
    PORT_PXE_PILOT=$(search_value ".pxePilot.port" 3478)
    PXE_PILOT_ENABLED=$(search_value ".pxePilot.enable" "false")
    PXE_PILOT_CFG=$(search_value ".pxePilot.config_after_reboot" "local")
    BOOT_MODE=$(search_value ".bootloader.mode" "uefi")
    if [ -z "${BOOT_SERVER}" ] ; then
		if [ "${PXE_PILOT_ENABLED}" == "true" ] ; then
			PXE_PILOT_BASEURL="$(search_mandatory_value .pxePilot.url \"Either 'ipAdr' or 'serverPxe' parameter must be provided\"):3478"
			local ret=$?
			if [ ${ret} -ne 0 ] ; then
				exit ${ret}
    	    fi
        fi
        LINUX_ROOTFS_URL=$(search_mandatory_value ".linux.image" "Either 'ipAdr' or 'linuxRootfs ' parameter must be provided")
        local ret=$?
        if [ ${ret} -ne 0 ] ; then
            exit ${ret}
        fi
		EFI_ARCHIVE_URL=$(search_mandatory_value .bootloader.image "Either 'ipAdr' or 'efiRootfs' parameter must be provided")
        local ret=$?
        if [ ${ret} -ne 0 ] ; then
            exit ${ret}
        fi
    else
    	PXE_PILOT_BASEURL="$(search_value '.pxePilot.url' 'http://${BOOT_SERVER}'):${PORT_PXE_PILOT}"
    	LINUX_ROOTFS_URL=$(search_value ".linux.image" "http://${BOOT_SERVER}/archive_root/${OS_NAME}/${OS_NAME}${OS_VERSION}_root.tar.gz")
    	EFI_ARCHIVE_URL=$(search_value ".bootloader.image" "http://${BOOT_SERVER}/archive_root/${OS_NAME}/${OS_NAME}${OS_VERSION}_efi.tar.gz")
    fi
    EFI_ENTRY_LABEL="${OS_NAME}"
    BLOCK_DEVICE=$(search_value ".linux.device" $(ls /dev/[hs]d[a-z] | head -1))
    EFI_PARTITION="${BLOCK_DEVICE}1"
    LINUX_PARTITION="${BLOCK_DEVICE}2"
    CODE_PARTITIONNING=8300
    SERIAL_TTY=$(search_value ".bootloader.kernel_parameter.console.serial" "ttyS1")
    BAUD_RATE=$(search_value ".bootloader.kernel_parameter.console.baudRate" "57600n8")
    SELINUX=$(search_value ".linux.selinux" "disable")
    if [ "${BOOT_MODE}" == "legacy" ] ; then
    	CODE_PARTITIONNING_BOOT=ef02
    	BOOT_PARTITION_SIZE=2M
	elif [ "${BOOT_MODE}" == "uefi" ] ; then
   		CODE_PARTITIONNING_BOOT=ef00
    	BOOT_PARTITION_SIZE=500M
	else
    	exit_on_error "Boot mode '${BOOT_MODE}' is not supported"
	fi

}

#
# Create two partitions on the drive. One system EFI partition to install
# the bootloader nad on for the Linux root filesystem. If some partitions
# previoulsly exist on the drive everything is wiped beforehand.
#
system_partitionning() {
    log_debug "-> ${FUNCNAME[0]} $*"

    echo ' ' ; echo 'Partitioning' ; echo ' '
    gdisk ${BLOCK_DEVICE} <<- EOF
	o
	Y
	n
	1

	+$BOOT_PARTITION_SIZE
	$CODE_PARTITIONNING_BOOT
	n
	2


	$CODE_PARTITIONNING_FS
	wq
	yes
	EOF
}


partitions_formating() {
    log_debug "-> ${FUNCNAME[0]} $*"

    if [ "${BOOT_MODE}" == "uefi" ] ; then
        mkfs.fat -F 32 -n EFI ${EFI_PARTITION}
    fi
    mkfs.ext4 -q -L cloudimg-rootfs ${LINUX_PARTITION} <<- EOF
	y
	EOF
    # TODO rootfs filesystem type should be an input parameter
}

#
# Create a directory : rootfs
# Mounts the root file system partition on this one
# Create two directories in it : boot and inside efi
# Mounts efi partition on efi directory
#
partitions_mounting() {
    log_debug "-> ${FUNCNAME[0]} $*"

    if [ -e ${rootfs} ] ; then
        rm -rf ${rootfs}
    fi
    mkdir ${rootfs}
    mount ${LINUX_PARTITION} ${rootfs}
    if [ "${BOOT_MODE}" == "uefi" ] ; then
        mkdir -p ${rootfs}/boot/efi
        mount ${EFI_PARTITION} ${rootfs}/boot/efi
    fi
}

#
# Download the file containing the root file system in /tmp directory and named it as linux_rootfs.
#
# The type supported are archive compressed like .tar.gz and .tar.xz, squashfs, qcow2.
#
# Analyses the type of root file system file and call function for extracting and copying the file system depending on the type.
#
linux_rootfs_installation() {
    log_debug "-> ${FUNCNAME[0]} $*"

    linux_image_dir=/mnt/image
    linux_image=/tmp/linux-rootfs

    wget --quiet -O ${linux_image} ${LINUX_ROOTFS_URL}

    if [ -e ${linux_image_dir} ] ; then
        rm -rf ${linux_image_dir}
    fi

    mkdir ${linux_image_dir}

    if [ -n "$(file ${linux_image} | grep XZ)" ] ; then
        archiveTar_installation "xfJ"
    elif [ -n "$(file ${linux_image} | grep gzip)" ] ; then
        archiveTar_installation "xzf"
    elif [ -n "$(file ${linux_image} | grep Squashfs)" ] ; then
        rm -rf ${linux_image_dir}
        squashfs_installation
    elif [ -n "$(file ${linux_image} | grep QCOW)" ] ; then
        qcow2_installation
    elif [ -n "$(file ${linux_image} | grep ISO)" ] ; then
        : #TODO : call functioninstallation for iso root fs
    fi
}

archiveTar_installation() {
    log_debug "-> ${FUNCNAME[0]} $*"

    (cd  ${linux_image_dir} ; tar ${1} ${linux_image})
    cp -rp ${linux_image_dir}/* ${rootfs}
}

squashfs_installation(){
    log_debug "-> ${FUNCNAME[0]} $*"

    unsquashfs -d ${linux_image_dir} ${linux_image}
    cp -rp ${linux_image_dir}/* ${rootfs}
}

qcow2_installation() {
    log_debug "-> ${FUNCNAME[0]} $*"

    DEBIAN_FRONTEND=noninteractive apt install -y libguestfs-tools
    guestmount -a ${linux_image} -m /dev/sda1 ${linux_image_dir}

    cp -rp ${linux_image_dir}/* ${rootfs}

    umount ${linux_image_dir}
}

bootloader_installation() {
    log_debug "-> ${FUNCNAME[0]} $*"

    if [ "${BOOT_MODE}" == "uefi" ] ; then
        bootloader_installation_uefi
    elif [ "${BOOT_MODE}" == "legacy" ] ; then
        grub-install --root-directory=${rootfs} ${BLOCK_DEVICE}
    fi
}

bootloader_installation_uefi() {
    log_debug "-> ${FUNCNAME[0]} $*"
    local bootloader_name=ubuntu # bootloader_name is used to name the bootloader folder
                                 # in the EFI partition. For now, it have to be 'ubuntu' and
                                 # can't be changed as long we rely on Grub EFI comming from
                                 # Cannonical because some paths are harcoded into binaries.

    local bootloader_dir=${rootfs}/boot/efi/EFI/${bootloader_name}
    local bootloader_archive_file=/tmp/efi.tar.gz

    wget --quiet -O ${bootloader_archive_file} ${EFI_ARCHIVE_URL}
    tar xvzf ${bootloader_archive_file} -C ${rootfs}/boot/efi
    rm -f ${bootloader_archive_file}
    cat <<- 'EOF' > ${bootloader_dir}/grub.cfg
	search --label cloudimg-rootfs --set
	set prefix=($root)'/boot/grub2'
	configfile $prefix/grub.cfg
	EOF

    efibootmgr -c -d ${BLOCK_DEVICE} -p 1 -L "${EFI_ENTRY_LABEL}" -l "\EFI\\${bootloader_name}\shimx64.efi"
}

# This function is useful to erase unecessary efi boot entry
#
# - Unecessary boot entry are those which have been added with a path to the bootloader
# - Permit to avoid bug after reboot
efi_entry_cleanup() {
    log_debug "-> ${FUNCNAME[0]} $*"

    num=$(efibootmgr -v | grep  "File" | cut -d ' ' -f 1 | grep "0" | cut -d 't' -f 2 | cut -d '*' -f 1)
    N=$(echo $num | wc -w)
    for i in $(seq 1 $N)
    do
        entry=$(echo $num | cut -d ' ' -f $i)
        efibootmgr -b $entry -B
    done
}

#
# Exec a command in the chroot context
#
# $@ - command to execute
#
chroot_exec() {
    log_debug "-> ${FUNCNAME[0]} $*"

    LANG=C chroot ${rootfs} $@
}

#
# Prepare chroot environement
#
# Copy the resolv.conf file of the live OS of grml live session to having DNS service
# As it, allow command with apt install in this chroot environment
#
prepare_chroot() {
    log_debug "-> ${FUNCNAME[0]} $*"

    mkdir -p ${rootfs}/proc
    mkdir -p ${rootfs}/sys
    mkdir -p ${rootfs}/dev
    mkdir -p ${rootfs}/dev/pts

    mount -t proc none ${rootfs}/proc
    mount -t sysfs none ${rootfs}/sys
    mount -o bind /dev ${rootfs}/dev
    mount -o bind /dev/pts ${rootfs}/dev/pts

    rm -f ${rootfs}/etc/resolv.conf
    cp /etc/resolv.conf ${rootfs}/etc/
}

# Create linux user and his directory, add it to the sudoers.
# /!\ Configure the /mnt/rootfs/etc/sudoers.d/linux as sudoer password not requested /!\
# Configure ssh
create_user() {
    log_debug "-> ${FUNCNAME[0]} $*"

    chroot_exec useradd --shell /bin/bash -m -d /home/linux linux
    echo "linux ALL=(ALL:ALL) NOPASSWD: ALL" > ${rootfs}/etc/sudoers.d/linux
    echo -e 'linux\nlinux' | chroot_exec passwd linux

    # FIXME : Hardcode my SSH key for test purpose because
    # password authentication is disabled in Ubuntu 18.04 image 
    #TODO :put it in parameter
    mkdir -p ${rootfs}/home/linux/.ssh/
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdXnRJVWf7OvFa0UZPkvDBave2BWhr29HFlO/bI/98rmPc0zn24a8Wplo/Sts4SrL3xZNATH5tWwNpPulBThPqnjdMU4Rw2Jf/mjlQXiT7+w3w60/HrMd62J/d/dyYrIuvuog3OAEi1vsiKCRm/9ptpbNA4E34ZUBSOpT3bx0b4NszYB2g7VdcmgHHXSY16AVCv3I3ZN0UmWphw1hpjpxfHTinE2pR5L0HVMikxqaxjCZI7DSpi8f4gQJn7gjLTh905o751Z3s7Y4L/v9NTEXmCPF425krwxDD4EMSMJ6BXgAExvPolWV0/W9HUtKX7XtEJUKWLUlikb7qTRWR1sld ubuntu@dev-01' > ${rootfs}/home/linux/.ssh/authorized_keys
    chroot_exec chown -R linux: /home/linux/.ssh
    
    if [ ${bootMode} == "legacy" ] ; then
        # Workaround for some hardware running with legacy boot that have problem with the two following modules
		cat <<- EOF >> ${rootfs}/etc/modprobe.d/blacklist.conf
		blacklist me
		blacklist mei_me
		EOF
	fi
}

configure_fstab() {
    log_debug "-> ${FUNCNAME[0]} $*"

    cat <<- EOF > ${rootfs}/etc/fstab
	LABEL=cloudimg-rootfs /                       ext4     defaults        0 0
	EOF

    if [ "${BOOT_MODE}" == "uefi" ] ; then
	cat <<- EOF >> ${rootfs}/etc/fstab
	LABEL=EFI             /boot/efi               vfat     defaults        0 0
	EOF
    fi
}

remove_cloudinit() {
    log_debug "-> ${FUNCNAME[0]} $*"

    if [ -d ${rootfs}/etc/yum ] ; then
        chroot_exec yum -y erase cloud-init
    elif [ -d ${rootfs}/etc/apt ] ; then
        chroot_exec apt-get -y purge cloud-init
        chroot_exec dpkg-reconfigure openssh-server
    fi
}

configure_networking() {
    log_debug "-> ${FUNCNAME[0]} $*"

    if [ -d ${rootfs}/etc/netplan ] ; then
        log "Configuring Linux | Configure network interface | Netplan configuration detected"
        cat <<- EOF > ${rootfs}/etc/netplan/network.yaml
		network:
		    version: 2
		    ethernets:
		        ${PUBLIC_IFACE_NAME}:
		            dhcp4: true
		            dhcp6: false
		EOF
    elif [ -e ${rootfs}/etc/network/interfaces ] ; then
        log "Configuring Linux | Configure network interface | /etc/network/interfaces configuration detected"
        cat <<- EOF > ${rootfs}/etc/network/interfaces
		auto lo
		iface lo inet loopback

		auto ${PUBLIC_IFACE_NAME}
		iface ${PUBLIC_IFACE_NAME} inet dhcp
		EOF
    elif [ -d ${rootfs}/etc/sysconfig/network-scripts ] ; then
        log "Configuring Linux | Configure network interface | SysConfig configuration detected"
        cat <<- EOF > ${rootfs}/etc/sysconfig/network-scripts/ifcfg-${PUBLIC_IFACE_NAME}
		DEVICE="${PUBLIC_IFACE_NAME}"
		BOOTPROTO="dhcp"
		ONBOOT="yes"
		TYPE="Ethernet"
		USERCTL="yes"
		PEERDNS="yes"
		IPV6INIT="no"
		PERSISTENT_DHCLIENT="1"
		EOF
    else
        log_warning "Configuring Linux | Configure network interface | No configuration detected"
    fi
}

cleanup_rootfs() {
    log_debug "-> ${FUNCNAME[0]} $*"

    rm -f ${rootfs}/etc/resolv.conf
}

linux_rootfs_configuration() {
    log_debug "-> ${FUNCNAME[0]} $*"

    log "Configuring Linux | Prepare chroot environment"
    prepare_chroot

    log "Configuring Linux | Configure partitions mount in /etc/fstab"
    configure_fstab

    log "Configuring Linux | Create a sudoer user"
    create_user

    log "Configuring Linux | Configure GRUB bootloader"
    rootfs_bootloader_configuration

    log "Configuring Linux | Remove cloud-init if present"
    remove_cloudinit

    log "Configuring Linux | Configure network interface"
    configure_networking

    log "Configuring Linux | Cleanup the root filesystem"
    cleanup_rootfs
}

#
# Verification of grub.cfg file presence
# Existing grub.cfg file is used to check the path to the kernel an initrd file
# These paths are used to recreate a new grub.cfg file
#
rootfs_bootloader_configuration() {
    log_debug "-> ${FUNCNAME[0]} $*"

    local grubFile=${rootfs}/boot/grub2/grub.cfg
    local legacyGrubFile=${rootfs}/boot/grub/grub.cfg

    if [ -e ${grubFile} ] ; then
        cp ${grubFile} ${grubFile}.bak
        if [ ${BOOT_MODE} == "legacy" ] && [ ! -e ${legacyGrubFile} ]; then
            (cd ${rootfs}/boot/grub2 && ln -s ./../grub2/grub.cfg ./../grub/grub.cfg)
        fi
    else
        if [ ! -e ${legacyGrubFile} ] ; then
            exit_on_error "Unable to locate GRUB config file"
        fi
        mkdir -p ${rootfs}/boot/grub2/
        cp ${legacyGrubFile} ${grubFile}
        mv ${legacyGrubFile} ${legacyGrubFile}.bak
        (cd ${rootfs}/boot/grub && ln -s ../grub2/grub.cfg .)
    fi

    local kernel=$(grep -o -m 1 -e  'linux\(16\)*\s*[^/]*/boot/[^ ]*' ${grubFile} | sed -e's#.*\(/boot/.*\)#\1#')
    local initrd=$(grep -o -m 1 -e 'initrd\(16\)*\s*[^/]*/boot/[^ ]*' ${grubFile} | sed -e's#.*\(/boot/.*\)#\1#')

    if [[ -z "${kernel}" || -z ${initrd} ]] ; then
        # TODO Handle files in /mnt/boot/loader/entries/ for Fedora
        # e.g. /mnt/boot/loader/entries/f241772f3e32496c92975269b5794615-5.0.9-301.fc30.x86_64.conf
        :
        if [[ -z "${kernel}" || -z ${initrd} ]] ; then
            exit_on_error "Can't find kernel or initrd file path"
        fi
    fi

    cat <<- EOF > ${grubFile}
	default=0
	timeout=5
	
	menuentry 'Linux' {
	    insmod gzio
	    search --label cloudimg-rootfs --set
	    linux  ${kernel} root=LABEL=cloudimg-rootfs ro console=${SERIAL_TTY},${BAUD_RATE}
	    initrd ${initrd}
	}
	EOF
}

#
# This function disable the SElinux service in the configuration file by default
# If selinux variable is set to enable, it create the file .autorelabel on root : selinux uses extended attributes
# and by copying the rootfile system this way, it comes to a problem on it
#
# So SElinux is locking everyfing. You can't log after reboot.
# Having the file .autorelabel after reboot involves two reboots before beeing able to login.
# At the first reboot, the presence of .autorelabel launch the relabelling of all files.
# Then the system reboot and you're able to login.
#
SElinux_configuration(){
    log_debug "-> ${FUNCNAME[0]} $*"

    local config_file=${rootfs}/etc/selinux/config
    if [ -e ${config_file} ]; then
        if [ "${SELINUX}" == "enable" ]; then
            touch ${rootfs}/.autorelabel
        else
            sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/' ${config_file}
        fi
    fi
}

partitions_unmounting() {
    log_debug "-> ${FUNCNAME[0]} $*"

    cd /
    umount -R ${rootfs}
}

notify_pxepilot_and_reboot() {
    log_debug "-> ${FUNCNAME[0]} $*"

    macA=$(ip address | grep -A 1 "${PUBLIC_IFACE_NAME}" | grep "link/ether" | cut -d ' ' -f 6)
    if [ "${PXE_PILOT_ENABLED}" == "true" ] ; then
       curl -i -X PUT "${PXE_PILOT_BASEURL}/v1/configurations/${PXE_PILOT_CFG}/deploy" -d '{"hosts":[{"macAddress":"'"$macA"'"}]}'
    fi
    reboot
}

main() {
	log_debug "-> ${FUNCNAME[0]} $*"

	log "Starting installation process"

	rootfs=/mnt/rootfs

	log "Preparing tools required for installation"
        prepare_env

	log "Download configuration file"
	load_config

	log "Reading input configuration"
	config_variable

	log "Cleaning local boot EFI entries from the EFI Boot Manager"
	if [ "${BOOT_MODE}" == "uefi" ] ; then
            efi_entry_cleanup
        fi

	log "Erasing drive an creating the partition table"
	system_partitionning

	log "Formating partitions"
    partitions_formating

	log "Mount partition in read-write mode"
	partitions_mounting

	log "Installing Linux root filesystem into the Linux partition"
	linux_rootfs_installation

	log "Installing bootloader"
	bootloader_installation

	log "Configuring Linux"
	linux_rootfs_configuration

	log "Configuring SELinux if present"
	SElinux_configuration

	log "Unmounting partitions"
	partitions_unmounting

	log "Installation complete. Notify PXE Pilot and reboot system"
	notify_pxepilot_and_reboot
}

if [ "$(basename $0)" = "os-install.sh" ] ; then
	set -x
	main 2>&1 | tee /var/log/os-install.log
fi
