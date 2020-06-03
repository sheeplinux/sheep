#!/usr/bin/env bats

load test_tool

@test "test network protocol mode of interface" {
    file_path=$(search_value "${CURRENT_KEY}".data.filePath)
    mode=$(search_value "${CURRENT_KEY}".data.mode)

    run ssh_cmd "${IP}" "${USER}" "${PASSWORD}" "cat ${file_path}"

    [ ${status} -eq 0 ]
    [ $(echo "${output}" | grep "${mode}" | wc -l) -ge 1 ]
}

@test "test ip address value if given" {

    static_add=$(search_value ."${CURRENT_KEY}".data.ipAdd)

    if [ "${static_add}" == "null" ]; then 
        skip "No static address to test"
    fi

    run ssh_cmd "${IP}" "${USER}" "${PASSWORD}" "sudo ip add"

    [ ${status} -eq 0 ]
    [ $(echo "${output}" | grep "${static_add}/" | wc -l) -ge 1 ]
}
