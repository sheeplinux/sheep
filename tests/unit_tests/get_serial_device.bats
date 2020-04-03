#!/usr/bin/env bats

load test_helper

@test "get_serial_device return linux device matching the console kernel parameter" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export SHEEP_PARAMETERS='sheep.script=http://sheep console=ttyS1'

    run get_serial_device

    [ "${status}" -eq 0 ]
    [ "${output}" = "/dev/ttyS1" ]
}

@test "get_serial_device return linux device matching the console with console defined twice" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export SHEEP_PARAMETERS='console=tty1 sheep.script=http://sheep console=ttyS2,115200'

    run get_serial_device

    [ "${status}" -eq 0 ]
    [ "${output}" = "/dev/ttyS2" ]
}

@test "get_serial_device return linux device when console paramter is not defined" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export SHEEP_PARAMETERS='sheep.script=http://sheep'

    run get_serial_device

    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}
