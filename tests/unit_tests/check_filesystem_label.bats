#!/usr/bin/env bats

load test_helper

@test "check_filesystem_label with 0123456789ab (12 characters)" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    run check_filesystem_label 0123456789ab
    [ "${status}" -eq 0 ]
}

@test "check_filesystem_label with 0123456789abc (13 character)" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    run check_filesystem_label 0123456789abc 
    [ "${status}" -eq 1 ]
    [ "${output}" = "ERROR : Number of character exceed maximal size : 12 characters max" ]
}

@test "check_filesystem_label with A12_45-789zb (12 characters, all authorized characters)" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    run check_filesystem_label A12_45-789zb
    [ "${status}" -eq 0 ]
}

@test "check_filesystem_label with 0123456789@ (less than 12 character)" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    run check_filesystem_label 0123456789@ 
    [ "${status}" -eq 1 ]
    [ "${output}" = "ERROR : Invalid character used in the name given to filesystem : character must be a number, a letter '_' or '-'" ]
}

@test "check_filesystem_label with 0123456789# (less than 12 character)" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    run check_filesystem_label 0123456789# 
    [ "${status}" -eq 1 ]
    [ "${output}" = "ERROR : Invalid character used in the name given to filesystem : character must be a number, a letter '_' or '-'" ]
}

@test "check_filesystem_label with 0123456789* (less than 12 character)" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    run check_filesystem_label 0123456789* 
    [ "${status}" -eq 1 ]
    [ "${output}" = "ERROR : Invalid character used in the name given to filesystem : character must be a number, a letter '_' or '-'" ]
}

@test "check_filesystem_label with 0123456789% (less than 12 character)" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    run check_filesystem_label 0123456789% 
    [ "${status}" -eq 1 ]
    [ "${output}" = "ERROR : Invalid character used in the name given to filesystem : character must be a number, a letter '_' or '-'" ]
}

@test "check_filesystem_label with 0123456789+ (less than 12 character)" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    run check_filesystem_label 0123456789+ 
    [ "${status}" -eq 1 ]
    [ "${output}" = "ERROR : Invalid character used in the name given to filesystem : character must be a number, a letter '_' or '-'" ]
}

@test "check_filesystem_label with 0123456789! (less than 12 character)" {
    source ${BATS_TEST_DIRNAME}/../../sheep

    run check_filesystem_label 0123456789! 
    [ "${status}" -eq 1 ]
    [ "${output}" = "ERROR : Invalid character used in the name given to filesystem : character must be a number, a letter '_' or '-'" ]
}
