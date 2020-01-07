#!/usr/bin/env bats

load test_helper

@test "search_mandatory_value with existing values" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgTestSearch_m_v1.yml
    
    run search_mandatory_value .param1
    [ "${status}" -eq 0 ]
    [ "${output}" = "value1" ]

    flush_log

    run search_mandatory_value .param2
    [ "${status}" -eq 0 ]
    [ "${output}" = "value2" ]

    flush_log

    run search_mandatory_value .param3
    [ "${status}" -eq 0 ]
    [ "${output}" = "value3" ]
}

@test "search_mandatory_value with no values" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgTestSearch_m_v2.yml

    run search_mandatory_value .param1 
    [ "${status}" -eq 1 ]

    flush_log

    run search_mandatory_value .param2
    [ "${status}" -eq 1 ]

    flush_log

    run search_mandatory_value .param3
    [ "${status}" -eq 1 ]
}

@test "search_mandatory_value with not existing param and an error message" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgTestSearch_m_v3.yml

    run search_mandatory_value .param4 "No param4"
    [ "${status}" -eq 1 ]
    [ "${output}" = "ERROR : No param4" ]
}


