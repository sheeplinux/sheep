#!/usr/bin/env bats

load test_helper

init_log_test() {
    export OS_INSTALL_LOG_FILE=$(mktemp)
    export OS_INSTALL_LOG_LEVEL=$1
    source ${BATS_TEST_DIRNAME}/../../os-install.sh
}

check_log_error_present() {
    init_log_test $1

    run log_error "This is an error message"

    [ "${status}" -eq 0 ]
    [ $(cat ${OS_INSTALL_LOG_FILE} | wc -l) -eq 1 ]
    [[ "$(cat ${OS_INSTALL_LOG_FILE})" =~ 'ERROR   | This is an error message' ]]
}

@test "log_error present when log level is ERROR" {
    check_log_error_present ERROR
}

@test "log_error present when log level is WARNING" {
    check_log_error_present WARNING
}

@test "log_error present when log level is INFO" {
    check_log_error_present INFO
}

@test "log_error present when log level is DEBUG" {
    check_log_error_present DEBUG
}

check_log_warning_present() {
    init_log_test $1

    run log_warning "This is an warning message"
    [ "${status}" -eq 0 ]
    [ $(cat ${OS_INSTALL_LOG_FILE} | wc -l) -eq 1 ]
    [[ "$(cat ${OS_INSTALL_LOG_FILE})" =~ 'WARNING | This is an warning message' ]]
}

check_log_warning_absent() {
    init_log_test $1

    run log_warning "This is an warning message"
    [ "${status}" -eq 0 ]
    [ $(cat ${OS_INSTALL_LOG_FILE} | wc -l) -eq 0 ]
}

@test "log_warning absent when log level is ERROR" {
    check_log_warning_absent ERROR
}

@test "log_warning present when log level is WARNING" {
    check_log_warning_present WARNING
}

@test "log_warning present when log level is INFO" {
    check_log_warning_present INFO
}

@test "log_warning present when log level is DEBUG" {
    check_log_warning_present DEBUG
}

check_log_info_present() {
    init_log_test $1

    run log_info "This is an info message"
    [ "${status}" -eq 0 ]
    [ $(cat ${OS_INSTALL_LOG_FILE} | wc -l) -eq 1 ]
    [[ "$(cat ${OS_INSTALL_LOG_FILE})" =~ 'INFO    | This is an info message' ]]
}

check_log_info_absent() {
    init_log_test $1

    run log_info "This is an info message"
    [ "${status}" -eq 0 ]
    [ $(cat ${OS_INSTALL_LOG_FILE} | wc -l) -eq 0 ]
}

@test "log_info absent when log level is ERROR" {
    check_log_info_absent ERROR
}

@test "log_info absent when log level is WARNING" {
    check_log_info_absent WARNING
}

@test "log_info present when log level is INFO" {
    check_log_info_present INFO
}

@test "log_info present when log level is DEBUG" {
    check_log_info_present DEBUG
}

check_log_present() {
    init_log_test $1

    run log "This is an info message"
    [ "${status}" -eq 0 ]
    [ $(cat ${OS_INSTALL_LOG_FILE} | wc -l) -eq 1 ]
    [[ "$(cat ${OS_INSTALL_LOG_FILE})" =~ 'INFO    | This is an info message' ]]
}

check_log_absent() {
    init_log_test $1

    run log "This is an info message"
    [ "${status}" -eq 0 ]
    [ $(cat ${OS_INSTALL_LOG_FILE} | wc -l) -eq 0 ]
}

@test "log absent when log level is ERROR" {
    check_log_absent ERROR
}

@test "log absent when log level is WARNING" {
    check_log_absent WARNING
}

@test "log present when log level is INFO" {
    check_log_present INFO
}

@test "log present when log level is DEBUG" {
    check_log_present DEBUG
}

check_log_debug_present() {
    init_log_test $1

    run log_debug "This is a debug message"
    [ "${status}" -eq 0 ]
    [ $(cat ${OS_INSTALL_LOG_FILE} | wc -l) -eq 1 ]
    [[ "$(cat ${OS_INSTALL_LOG_FILE})" =~ 'DEBUG   | This is a debug message' ]]
}

check_log_debug_absent() {
    init_log_test $1

    run log_debug "This is a debug message"
    [ "${status}" -eq 0 ]
    [ $(cat ${OS_INSTALL_LOG_FILE} | wc -l) -eq 0 ]
}

@test "log_debug absent when log level is ERROR" {
    check_log_debug_absent ERROR
}

@test "log_debug absent when log level is WARNING" {
    check_log_debug_absent WARNING
}

@test "log_debug absent when log level is INFO" {
    check_log_debug_absent INFO
}

@test "log_info present when log level is DEBUG" {
    check_log_debug_present DEBUG
}
