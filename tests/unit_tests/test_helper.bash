#!/bin/bash

BATS_OUT_LOG=${BATS_TEST_DIRNAME}/${TEST_LOG_FILE:-test.log}

setup() {
	{
		title "#${BATS_TEST_NUMBER} | Begin test | ${BATS_TEST_NAME} | ${BATS_TEST_FILENAME}"
	} >> ${BATS_OUT_LOG}
}

teardown() {
	flush_log
	{
		title "#${BATS_TEST_NUMBER} | End test   | ${BATS_TEST_NAME} | ${BATS_TEST_FILENAME}"
	} >> ${BATS_OUT_LOG}
}

title() {
	{
		echo ""
		echo "---------------------------------------------------------------------------------------------------------------------"
		echo "--- ${1}"
		echo "---------------------------------------------------------------------------------------------------------------------"
		echo ""
	} >> ${BATS_OUT_LOG}
}

flush_log() {
	{
		echo "${lines[@]}"
	} >> ${BATS_OUT_LOG}
}
