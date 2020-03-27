#!/usr/bin/env bats

load test_helper

@test "search_value with existing values" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgTestSearch_m_v1.yml

    run search_value .param1
    [ "${status}" -eq 0 ]
    [ "${output}" = "value1" ]

    flush_log

    run search_value .param2
    [ "${status}" -eq 0 ]
    [ "${output}" = "value2" ]

    flush_log

    run search_value .param3
    [ "${status}" -eq 0 ]
    [ "${output}" = "value3" ]
}

@test "search_value with existing values with a default value" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgTestSearch_m_v1.yml

    run search_value .param1 default
    [ "${status}" -eq 0 ]
    [ "${output}" = "value1" ]

    flush_log

    run search_value .param2 default
    [ "${status}" -eq 0 ]
    [ "${output}" = "value2" ]

    flush_log

    run search_value .param3 default
    [ "${status}" -eq 0 ]
    [ "${output}" = "value3" ]
}

@test "search_value with not existing param and no default value" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgTestSearch_m_v3.yml 

    run search_value .param4
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "search_value with not existing param and a default value" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgTestSearch_m_v3.yml

    run search_value .param4 "defaultForParam4"
    [ "${status}" -eq 0 ]
    [ "${output}" = "defaultForParam4" ]
}

@test "search_value with not existing param and no default value and optionyamlValue" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgTestSearch_m_v4.yml

    run search_value ".cloudInit.userData" "" "yaml"
    [ "${status}" -eq 0 ]
    [ "${output}" = "users:
  - name: linux
    lock_passwd: false
    ssh_authorized_keys: ssh-rsa ojoihdahioahdjnfnainfioajefijaeoifhaoiehfioah apkpẑakdkzepojfijzeifjiozefiozejiofhozehfoheofheaoha
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
chpasswd:
  expire: false
  list: |
    linux:linux
ssh_pwauth: true" ]
}