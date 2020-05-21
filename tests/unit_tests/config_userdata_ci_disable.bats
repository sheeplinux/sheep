#!/usr/bin/env bats

load test_helper

@test "config_userdata_ci_disable with ssh key and password given " {
    source ${BATS_TEST_DIRNAME}/../../sheep
    export cloudfs=$(mktemp -d)
    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgUserDataCID1.yml
    userdata=${cloudfs}/user-data

    run config_userdata_ci_disable

    ssh_key=$(yq -r ".users[0].ssh_authorized_keys" "${userdata}")
    password=$(yq -r ".chpasswd.list" "${userdata}" | head -1)

    [ "${status}" -eq 0 ]
    [ "${ssh_key}" = "ssh" ]
    [ "${password}" = "linux:linux" ]
    rm -r ${cloudfs}
}

@test "config_userdata_ci_disable with ssh key given and no password " {
    source ${BATS_TEST_DIRNAME}/../../sheep
    export cloudfs=$(mktemp -d)
    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgUserDataCID2.yml
    userdata=${cloudfs}/user-data

    run config_userdata_ci_disable

    ssh_key=$(yq -r ".users[0].ssh_authorized_keys" "${userdata}")
    password=$(yq -r ".chpasswd.list" "${userdata}" | head -1)

    [ "${status}" -eq 0 ]
    [ "${ssh_key}" == "ssh" ]
    [ "${password}" == "null" ]
    rm -r ${cloudfs}
}

@test "config_userdata_ci_disable with password and no ssh key" {
    source ${BATS_TEST_DIRNAME}/../../sheep
    export cloudfs=$(mktemp -d)
    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgUserDataCID3.yml
    userdata=${cloudfs}/user-data

    run config_userdata_ci_disable

    ssh_key=$(yq -r ".users[0].ssh_authorized_keys" "${userdata}")
    password=$(yq -r ".chpasswd.list" "${userdata}" | head -1)

    [ "${status}" -eq 0 ]
    [ "${ssh_key}" == "null" ]
    [ "${password}" == "linux:linux" ]
    rm -r ${cloudfs}
}

@test "config_userdata_ci_disable with no password and no ssh key" {
    source ${BATS_TEST_DIRNAME}/../../sheep
    export cloudfs=$(mktemp -d)
    export CONFIG_FILE=${BATS_TEST_DIRNAME}/sheepCfgUserDataCID4.yml
    userdata=${cloudfs}/user-data

    run config_userdata_ci_disable

    ssh_key=$(yq -r ".users[0].ssh_authorized_keys" "${userdata}")
    password=$(yq -r ".chpasswd.list" "${userdata}" | head -1)

    [ "${status}" -eq 1 ]
    [ "${ssh_key}" == "null" ]
    [ "${password}" == "null" ]
    rm -r ${cloudfs}
}
