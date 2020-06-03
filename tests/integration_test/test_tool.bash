#!/bin/bash

#
# Run a command through SSH
#
# $1 - Linux IP
# $2 - Linux username
# $3 - Linux password
# $* Command to execute
#
ssh_cmd() {
	local ip=$1
	local username=$2
	local password=$3
	shift
	shift
	shift
	{
		timeout 20 sshpass -p ${password} \
			ssh -o StrictHostKeyChecking=no \
			-o UserKnownHostsFile=/dev/null \
			-o LogLevel=QUIET \
			${username}@${ip} "$*"
		return $?
	} < /dev/null
}

#
# search_value returns a piece of configuration from the Sheep YAML configuration file.
#
# The function call parser yq with -w 10000 parameters to parse correctly long sized value
# With -Y to parse correctly when the key have subkeys.
#
# $1 - Parameter identifier
# $2 - Parsing option (possible values are 'string' or 'yaml'. Default is 'string')
#
search_value() {

	if [ -z "${2}" ] || [ "${2}" == "string" ]; then
		local value=$(yq -r "${1}" "${INPUT_TEST}")
		echo "${value}"
	elif [ "${2}" == "yaml" ]; then
		yq -r -Y -w 100000 "${1}" "${INPUT_TEST}"
	fi
}
