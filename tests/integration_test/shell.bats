#!/usr/bin/env bats

load test_tool

@test "test shell value for the system" {
    test_input=$(search_value "${CURRENT_KEY}".data)

    run ssh_cmd "${IP}" "${USER}" "${PASSWORD}" echo '$SHELL'

    [ ${status} -eq 0 ]
    [ "${output}" == "${test_input}" ]
}
