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
    OS_NAME=$(search_value osType "linux")
    OS_VERSION=$(search_value osVersion "current")
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
    EFI_ENTRY_LABEL="${OS_NAME}"
    BLOCK_DEVICE=$(search_value blockDevice $(ls /dev/[hs]d[a-z] | head -1))
    EFI_PARTITION="${BLOCK_DEVICE}1"
    LINUX_PARTITION="${BLOCK_DEVICE}2"
    CODE_PARTITIONNING=8300
    SELINUX=$(search_value selinux "disable")
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
    mkfs.ext4 -q -L cloudimg-rootfs ${LINUX_PARTITION} <<- EOF
	y
	EOF
    # TODO rootfs filesystem type should be an input parameter
}

partitions_mounting() {
    if [ -e ${rootfs} ] ; then
        rm -rf ${rootfs}
    fi
    mkdir ${rootfs}
    mount ${LINUX_PARTITION} ${rootfs}
    mkdir -p ${rootfs}/boot/efi
    mount ${EFI_PARTITION} ${rootfs}/boot/efi
}

linux_rootfs_installation() {
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
        echo 'o' #TODO : call functioninstallation for iso root fs
    fi
}

archiveTar_installation() {
    (cd  ${linux_image_dir} ; tar ${1} ${linux_image})
    cp -rp ${linux_image_dir}/* ${rootfs}
}

squashfs_installation(){
    unsquashfs -d ${linux_image_dir} ${linux_image}
    cp -rp ${linux_image_dir}/* ${rootfs}
}

qcow2_installation() {
    ### Workaround for Debian repos issue when runnning GRML
    ###     E: The repository 'http://security.debian.org testing/updates Release' does not have a Release file.
    ### We don't need this package repository so we delete it
    cat <<- 'EOF' > /etc/apt/sources.list.d/debian.list
	deb     http://snapshot.debian.org/archive/debian/20181230/ testing main contrib non-free
	deb-src http://snapshot.debian.org/archive/debian/20181230/ testing main contrib non-free
	EOF

    apt update
    apt install -y libguestfs-tools

    guestmount -a ${linux_image} -m /dev/sda1 ${linux_image_dir}

    cp -rp ${linux_image_dir}/* ${rootfs}

    umount ${linux_image_dir}
}

bootloader_installation() {

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
# - Unecessary boot entry are those which have been add with a path to the bootloader
# - Permit to avoid bug after reboot
efi_entry_cleanup() {
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
    LANG=C chroot ${rootfs} $@
}

prepare_chroot() {
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

create_user() {
    chroot_exec useradd --shell /bin/bash -m -d /home/linux linux
    echo "linux ALL=(ALL:ALL) NOPASSWD: ALL" > ${rootfs}/etc/sudoers.d/linux
    echo -e 'linux\nlinux' | chroot_exec passwd linux

    # FIXME : Hardcode my SSH key for test purpose because
    # password authentication is disabled in Ubuntu 18.04 image 
    mkdir -p ${rootfs}/home/linux/.ssh/
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdXnRJVWf7OvFa0UZPkvDBave2BWhr29HFlO/bI/98rmPc0zn24a8Wplo/Sts4SrL3xZNATH5tWwNpPulBThPqnjdMU4Rw2Jf/mjlQXiT7+w3w60/HrMd62J/d/dyYrIuvuog3OAEi1vsiKCRm/9ptpbNA4E34ZUBSOpT3bx0b4NszYB2g7VdcmgHHXSY16AVCv3I3ZN0UmWphw1hpjpxfHTinE2pR5L0HVMikxqaxjCZI7DSpi8f4gQJn7gjLTh905o751Z3s7Y4L/v9NTEXmCPF425krwxDD4EMSMJ6BXgAExvPolWV0/W9HUtKX7XtEJUKWLUlikb7qTRWR1sld ubuntu@dev-01' > ${rootfs}/home/linux/.ssh/authorized_keys
    chroot_exec chown -R linux: /home/linux/.ssh
}

configure_fstab() {
    cat <<- EOF > ${rootfs}/etc/fstab
	LABEL=cloudimg-rootfs /                       ext4     defaults        0 0
	LABEL=EFI             /boot/efi               vfat     defaults        0 0
	EOF
}

remove_cloudinit() {
    if [ -d ${rootfs}/etc/yum ] ; then
        chroot_exec yum -y erase cloud-init
    elif [ -d ${rootfs}/etc/apt ] ; then
        chroot_exec apt-get -y purge cloud-init
        chroot_exec dpkg-reconfigure openssh-server
    fi
}

configure_networking() {
    if [ -d ${rootfs}/etc/netplan ] ; then
        cat <<- EOF > ${rootfs}/etc/netplan/network.yaml
		network:
		    version: 2
		    ethernets:
		        ${PUBLIC_IFACE_NAME}:
		            dhcp4: true
		            dhcp6: false
		EOF
    elif [ -e ${rootfs}/etc/network/interfaces ] ; then
        cat <<- EOF > ${rootfs}/etc/network/interfaces
		auto lo
		iface lo inet loopback

		auto ${PUBLIC_IFACE_NAME}
		iface ${PUBLIC_IFACE_NAME} inet dhcp
		EOF
    elif [ -d ${rootfs}/etc/sysconfig/network-scripts ] ; then
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
        # Something else ?
        :
    fi
}

cleanup_rootfs() {
    rm -f ${rootfs}/etc/resolv.conf
}

linux_rootfs_configuration() {
    prepare_chroot
    configure_fstab
    create_user
    rootfs_bootloader_configuration
    remove_cloudinit
    configure_networking
    cleanup_rootfs
}

rootfs_bootloader_configuration() {
    local grubFile=${rootfs}/boot/grub2/grub.cfg

    if [ -e ${grubFile} ] ; then
        cp ${grubFile} ${grubFile}.bak
    else
        local legacyGrubFile=${rootfs}/boot/grub/grub.cfg

        if [ ! -e ${legacyGrubFile} ] ; then
            exitOnError "Unable to locate GRUB config file"
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
            exitOnError "Can't find kernel or initrd file path"
        fi
    fi

    cat <<- EOF > ${grubFile}
	default=0
	timeout=5
	
	menuentry 'Linux' {
	    insmod gzio
	    search --label cloudimg-rootfs --set
	    linux  ${kernel} root=LABEL=cloudimg-rootfs ro console=ttyS1,57600n8
	    initrd ${initrd}
	}
	EOF
}

SElinux_configuration(){
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
    cd
    umount -R ${rootfs}
}

notify_pxepilot_and_reboot() {
    macA=$(ip address | grep -A 1 "${PUBLIC_IFACE_NAME}" | grep "link/ether" | cut -d ' ' -f 6)
    curl -i -X PUT "${PXE_PILOT_BASEURL}/v1/configurations/local/deploy" -d '{"hosts":[{"macAddress":"'"$macA"'"}]}'
    reboot
}

main() {
	rootfs=/mnt/rootfs

	config_variable
	efi_entry_cleanup
	system_partitionning
	partitions_formating
	partitions_mounting
	linux_rootfs_installation
	bootloader_installation
	linux_rootfs_configuration
	SElinux_configuration   
	partitions_unmounting
	notify_pxepilot_and_reboot
}

if [ "$(basename $0)" = "os-install.sh" ] ; then
	set -x
	main 2>&1 | tee /var/log/os-install.log
fi
