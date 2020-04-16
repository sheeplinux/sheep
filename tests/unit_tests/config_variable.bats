#!/usr/bin/env bats

load test_helper

@test "config_variable with .network.interface, .bootloader.mode, .linux.image, .bootloader.image and .pxePilot.enable=false" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable1.yml

    run config_variable
    [ "${status}" -eq 0 ]
}

@test "config_variable with .network.interface, .bootloader.mode, .linux.image, .bootloader.image ,.pxePilot.url given and .pxePilot.enable=true" {
    source ${BATS_TEST_DIRNAME}/../../sheep
 
    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable2.yml

    run config_variable
    [ "${status}" -eq 0 ]

}

@test "config_variable with .pxePilot.url not given and .pxePilot.enable=true" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable3.yml

    run config_variable
    [ "${status}" -eq 1 ]
}

@test "config_variable with all mandatory parameter given except .linux.image" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable5.yml

    run config_variable
    [ "${status}" -eq 1 ]
}