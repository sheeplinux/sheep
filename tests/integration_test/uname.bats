#!/usr/bin/env bats

load test_tool

@test "test uname value for the system" {
    test_input=$(search_value "${CURRENT_KEY}".data)

    run ssh_cmd "${IP}" "${USER}" "${PASSWORD}" uname -a

    [ ${status} -eq 0 ]
    [ $(echo "${output}" | grep "${test_input}" | wc -l) -eq 1 ]
}
