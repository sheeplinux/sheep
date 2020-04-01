#!/usr/bin/env bats

load test_helper

@test "search_kernel_parameter with existing values" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export SHEEP_PARAMETERS='sheep.config=http://config.yml sheep.script=http://sheep.bash sheep.delay=5'

    run search_kernel_parameter sheep.config
    [ "${status}" -eq 0 ]
    [ "${output}" = "http://config.yml" ]

    flush_log

    run search_kernel_parameter sheep.script
    [ "${status}" -eq 0 ]
    [ "${output}" = "http://sheep.bash" ]

    flush_log

    run search_kernel_parameter sheep.delay
    [ "${status}" -eq 0 ]
    [ "${output}" = "5" ]
}

@test "search_kernel_parameter with existing values and a default value" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export SHEEP_PARAMETERS='sheep.config=http://config.yml sheep.script=http://sheep.bash sheep.delay=5'

    run search_kernel_parameter sheep.config default1
    [ "${status}" -eq 0 ]
    [ "${output}" = "http://config.yml" ]

    flush_log

    run search_kernel_parameter sheep.script default2
    [ "${status}" -eq 0 ]
    [ "${output}" = "http://sheep.bash" ]

    flush_log

    run search_kernel_parameter sheep.delay default3
    [ "${status}" -eq 0 ]
    [ "${output}" = "5" ]
}

@test "search_kernel_parameter with parameter defined twice return last" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export SHEEP_PARAMETERS='console=tty1 console=ttyS2,115200'

    run search_kernel_parameter console
    [ "${status}" -eq 0 ]
    [ "${output}" = "ttyS2,115200" ]
}

@test "search_kernel_parameter with non existing value returns empty string" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export SHEEP_PARAMETERS='sheep.config=http://config.yml sheep.script=http://sheep.bash sheep.delay=5'

    run search_kernel_parameter console
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "search_kernel_parameter with non existing value and default value returns default value" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    export SHEEP_PARAMETERS='sheep.config=http://config.yml sheep.script=http://sheep.bash sheep.delay=5'

    run search_kernel_parameter console tty3
    [ "${status}" -eq 0 ]
    [ "${output}" = "tty3" ]
}
