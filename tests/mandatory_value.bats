#!/usr/bin/env bats

load test_helper

@test "search_mandatory_value with existing values" {
    source ${BATS_TEST_DIRNAME}/../os-install.sh

    export OS_DEPLOY_PARAMETERS="param1=value1 param2=value2 param3=value3"

    run search_mandatory_value param1
    [ "${status}" -eq 0 ]
    [ "${output}" = "value1" ]

    flush_log

    run search_mandatory_value param2
    [ "${status}" -eq 0 ]
    [ "${output}" = "value2" ]

    flush_log

    run search_mandatory_value param3
    [ "${status}" -eq 0 ]
    [ "${output}" = "value3" ]
}

@test "search_mandatory_value with no existing values without default value" {
    source ${BATS_TEST_DIRNAME}/../os-install.sh

    export OS_DEPLOY_PARAMETERS="param1= param2= param3= "

    run search_mandatory_value param1 
    [ "${status}" -eq 1 ]

    flush_log

    run search_mandatory_value param2
    [ "${status}" -eq 1 ]

    flush_log

    run search_mandatory_value param3
    [ "${status}" -eq 1 ]
}

@test "search_mandatory_value with not existing param" {
    source ${BATS_TEST_DIRNAME}/../os-install.sh

    export OS_DEPLOY_PARAMETERS="param1=value1 param2=value2 param3=value3"

    run search_mandatory_value param4
    [ "${status}" -eq 1 ]
}


