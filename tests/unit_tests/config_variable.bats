#!/usr/bin/env bats

load test_helper

@test "config_variable with ipAdr given, pxePilotCfg given & pxePilotEnabled true" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export OS_DEPLOY_PARAMETERS="intName=value ipAdr=172.19.118.1 pxePilotEnabled=true pxePilotCfg=local"

    run config_variable       
    [ "${status}" -eq 0 ]
}

@test "config_variable with ipAdr & efiRootfs & linuxRootfs & pxePilotCfg given, and pxePilot not given, so pxe-pilot must be disable by default" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export OS_DEPLOY_PARAMETERS="intName=value ipAdr=172.19.118.1 efiRootfs=value linuxRootfs=value pxePilotCfg=local"
    
    run config_variable 
    [ "${status}" -eq 0 ]

}

@test "config_variable with no ipAdr , and no pxePilotEnabled, efiRootfs & linuxRootfs given" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export OS_DEPLOY_PARAMETERS="intName=value efiRootfs=value linuxRootfs=value pxePilotEnabled=true pxePilotCfg=local"
                              
    run config_variable 
    [ "${status}" -eq 1 ]
}

@test "config_variable with no ip Adr and pxePilotEnabled false and efiRootfs & linuxRootfs given" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export OS_DEPLOY_PARAMETERS="intName=value efiRootfs=value linuxRootfs=value pxePilotEnabled=false pxePilotCfg=local"

    run config_variable 
    [ "${status}" -eq 0 ]
}

@test "config_variable with ipAdr but  no intName" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export OS_DEPLOY_PARAMETERS="ipAdr=value"

    run config_variable
    [ "${status}" -eq 1 ]
}

@test "config_variable with no ipAdr,  but no linuxRootfs , but efiRootfs given and intName too" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export OS_DEPLOY_PARAMETERS="intName=value efiRootfs=value"

    run config_variable
    [ "${status}" -eq 1 ]
}

@test "config_variable with no ipAdr,  but no efiRootfs , but linuxRootfs given and intName too" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export OS_DEPLOY_PARAMETERS="intName=value linuxRootfs=value"

    run config_variable
    [ "${status}" -eq 1 ]
}

@test "config_variable with minimal configuration to work : ipAdr and intName given" {
    source ${BATS_TEST_DIRNAME}/../../os-install.sh

    export OS_DEPLOY_PARAMETERS="intName=value ipAdr=value"

    run config_variable
    [ "${status}" -eq 0 ]
}
