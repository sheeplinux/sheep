#!/usr/bin/env bats

load test_helper

@test "search_value with existing values" {
    source ${BATS_TEST_DIRNAME}/../os-install.sh

    export OS_DEPLOY_PARAMETERS="param1=value1 param2=value2 param3=value3"

    run search_value param1
    [ "${status}" -eq 0 ]
    [ "${output}" = "value1" ]

    flush_log

    run search_value param2
    [ "${status}" -eq 0 ]
    [ "${output}" = "value2" ]

    flush_log

    run search_value param3
    [ "${status}" -eq 0 ]
    [ "${output}" = "value3" ]
}

@test "search_value with existing values with a default value" {
    source ${BATS_TEST_DIRNAME}/../os-install.sh

    export OS_DEPLOY_PARAMETERS="param1=value1 param2=value2 param3=value3"

    run search_value param1 default
    [ "${status}" -eq 0 ]
    [ "${output}" = "value1" ]

    flush_log

    run search_value param2 default
    [ "${status}" -eq 0 ]
    [ "${output}" = "value2" ]

    flush_log

    run search_value param3 default
    [ "${status}" -eq 0 ]
    [ "${output}" = "value3" ]
}

@test "search_value with not existing param and no default value" {
    source ${BATS_TEST_DIRNAME}/../os-install.sh

    export OS_DEPLOY_PARAMETERS="param1=value1 param2=value2 param3=value3"

    run search_value param4
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "search_value with not existing param and a default value" {
    source ${BATS_TEST_DIRNAME}/../os-install.sh

    export OS_DEPLOY_PARAMETERS="param1=value1 param2=value2 param3=value3"

    run search_value param4 "defaultForParam4"
    [ "${status}" -eq 0 ]
    [ "${output}" = "defaultForParam4" ]
}
