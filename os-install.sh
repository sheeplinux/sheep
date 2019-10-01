#!/bin/bash

set -e

exitOnError() {
    echo "ERROR : $1"
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
    if [ ${#configMap[@]} -eq 0 ] ; then
		local cmd=${OS_DEPLOY_PARAMETERS}
		if [ -z "${cmd}" ] ; then
			cmd=$(cat /proc/cmdline)
		fi

		IFS=' ' read -r -a array <<< "${cmd}"
		for param in ${array[@]} ; do
			local key=$(echo "${param}" | cut -d '=' -f 1)
			local value=$(echo "${param}" | cut -d '=' -f 2-)
			configMap[${key}]=${value}
		done
    fi
    local value=${configMap[${1}]}
    echo ${value:-${2}}
}

#
# $1 - key
# $2 - error message if the value is not found
#
search_mandatory_value() {
    local value=$(search_value $1)
    [ -z "$value" ] && exitOnError "$2"
    echo "${value}"
}

config_variable() {
    OS_NAME=$(search_mandatory_value osType "'osType' parameter must be provided")
    OS_VERSION=$(search_mandatory_value osVersion "'osVersion' parameter must be provided")
    BOOT_SERVER=$(search_value ipAdr)
    PUBLIC_IFACE_NAME=$(search_mandatory_value intName "'intName' parameter must be provided")
    PORT_PXE_PILOT=$(search_value portPxe 3478)
    if [ -z "${BOOT_SERVER}" ] ; then
    	PXE_PILOT_BASEURL=$(search_mandatory_value serverPxe "Either 'ipAdr' or 'serverPxe' parameter must be provided")
	LINUX_ROOTFS_URL=$(search_mandatory_value linuxRootfs "Either 'ipAdr' or 'linuxRootfs ' parameter must be provided")
	EFI_ARCHIVE_URL=$(search_mandatory_value efiRootfs "Either 'ipAdr' or 'efiRootfs' parameter must be provided")
    else
    	PXE_PILOT_BASEURL=$(search_value serverPxe "http://${BOOT_SERVER}:${PORT_PXE_PILOT}")
    	LINUX_ROOTFS_URL=$(search_value linuxRootfs "http://${BOOT_SERVER}/archive_root/${OS_NAME}/${OS_NAME}${OS_VERSION}_root.tar.gz")
    	EFI_ARCHIVE_URL=$(search_value efiRootfs "http://${BOOT_SERVER}/archive_root/${OS_NAME}/${OS_NAME}${OS_VERSION}_efi.tar.gz")
    fi
    EFI_ENTRY_LABEL="${OS_NAME} ${OS_VERSION}"
    BLOCK_DEVICE=$(search_value blockDevice $(ls /dev/[hs]d[a-z] | head -1))
    EFI_PARTITION="${BLOCK_DEVICE}1"
    LINUX_PARTITION="${BLOCK_DEVICE}2"
    case $OS_NAME in
	ubuntu ) CODE_PARTITIONNING=8300
        ;;
    	centos ) CODE_PARTITIONNING=0700 ; SELINUX=$(search_value selinux "disable")
	;;
    esac

}

#
# Create two partitions on the drive. One system EFI partition to install
# the bootloader nad on for the Linux root filesystem. If some partitions
# previoulsly exist on the drive everything is wiped beforehand.
#


system_partitionning() {
    echo ' ' ; echo 'Partitioning' ; echo ' '
    gdisk ${BLOCK_DEVICE} <<- EOF
	o
	Y
	n
	1

	+500M
	ef00
	n
	2


	$CODE_PARTITIONNING
	wq
	yes
	EOF
}

partitions_formating() {
    echo ' ' ; echo 'Formating' ; echo ' '
    mkfs.fat -F 32 -n EFI ${EFI_PARTITION}
    case $OS_NAME in
        ubuntu ) mkfs.ext4 -q -L fs_root ${LINUX_PARTITION} <<- EOF
		y
		EOF
		 ;;
        centos ) mkfs.xfs -f -L fs_root ${LINUX_PARTITION}
                 ;;
    esac
}

partitions_mounting() {
    mount ${LINUX_PARTITION} /mnt
    mkdir -p /mnt/boot/efi
    mount ${EFI_PARTITION} /mnt/boot/efi
}


bootloader_installation() {
    cd /mnt/boot/efi
    local efi_archive=efi.tar.gz
    wget --quiet -O ${efi_archive} ${EFI_ARCHIVE_URL}
    tar -pzxf ${efi_archive}
    rm ${efi_archive}
}

efi_entry_creation() {
    efibootmgr -c -d ${BLOCK_DEVICE} -p 1 -L "${EFI_ENTRY_LABEL}" -l "\EFI\\"${OS_NAME}"\shimx64.efi"
}

linux_rootfs_installation() {
    cd /mnt
    local linux_rootfs=/tmp/linux-rootfs.tar.gz
    wget --quiet -O ${linux_rootfs} ${LINUX_ROOTFS_URL}
    tar -pzxf ${linux_rootfs}
    rm ${linux_rootfs}
}

linux_rootfs_configuration() {
    uuid=$(blkid | grep ${LINUX_PARTITION} | cut -d ' ' -f 3 | cut -d '"' -f 2)
    efiID=$(blkid | grep ${EFI_PARTITION} | cut -d ' ' -f 4 | cut -d '"' -f 2)
    if [ $OS_NAME = "ubuntu" ]; then
    	sed -i -e 's/rootID/'$uuid'/' /mnt/boot/grub/grub.cfg
    fi
    sed -i -e 's/rootID/'$uuid'/' /mnt/boot/efi/EFI/$OS_NAME/grub.cfg
    sed -i -e 's/efiID/'$efiID'/' /mnt/etc/fstab
    sed -i -e 's/rootID/'$uuid'/' /mnt/etc/fstab
}

SElinux_configuration(){
    if [ "${OS_NAME}" == "centos" ]; then
        if [ "${SELINUX}" == "enable" ]; then
            touch /mnt/.autorelabel
        else
            sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/' /mnt/etc/selinux/config
        fi
    fi
}

partitions_unmounting() {
    cd /
    umount -R /mnt
}

notify_pxepilot_and_reboot() {
    macA=$(ip address | grep -A 1 "${PUBLIC_IFACE_NAME}" | grep "link/ether" | cut -d ' ' -f 6)
    curl -i -X PUT "${PXE_PILOT_BASEURL}/v1/configurations/local/deploy" -d '{"hosts":[{"macAddress":"'"$macA"'"}]}'
    reboot
}

main() {
	config_variable
	system_partitionning
	partitions_formating
	partitions_mounting
	linux_rootfs_installation
	bootloader_installation
	efi_entry_creation
	linux_rootfs_configuration
	SElinux_configuration
	partitions_unmounting
	notify_pxepilot_and_reboot
}

if [ "$(basename $0)" = "os-install.sh" ] ; then
	set -x
	main 2>&1 | tee /var/log/os-install.log
fi
