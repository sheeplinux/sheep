#!/usr/bin/env bats

load test_helper

@test "config_variable with ipAdr given, pxePilotCfg given & pxePilotEnabled true" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable1.yml

    run config_variable
    [ "${status}" -eq 0 ]
}

@test "config_variable with ipAdr & efiRootfs & linuxRootfs & pxePilotCfg given, and pxePilot not given, so pxe-pilot must be disable by default" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh
 
    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable2.yml

    run config_variable
    [ "${status}" -eq 0 ]

}


@test "config_variable with no ipAdr , and pxePilotEnabled is true, efiRootfs & linuxRootfs given" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable3.yml
                         
    run config_variable
    [ "${status}" -eq 1 ]
}

@test "config_variable with no ip Adr and pxePilotEnabled false and efiRootfs & linuxRootfs given" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable4.yml

    run config_variable
    [ "${status}" -eq 0 ]
}

@test "config_variable with ipAdr but  no intName" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable5.yml

    run config_variable
    [ "${status}" -eq 1 ]
}

@test "config_variable with no ipAdr,  but no linuxRootfs , but efiRootfs given and intName too" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable6.yml

    run config_variable
    [ "${status}" -eq 1 ]
}

@test "config_variable with no ipAdr,  but no efiRootfs , but linuxRootfs given and intName too" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable7.yml    

    run config_variable
    [ "${status}" -eq 1 ]
}

@test "config_variable with minimal configuration to work : ipAdr and intName given" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgConfigVariable8.yml

    run config_variable
    [ "${status}" -eq 0 ]
}