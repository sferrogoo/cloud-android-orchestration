#!/bin/bash

function validate_components() {
    echo "Path of cvdr: ${CVDR_PATH}"
    echo "Path of the configuration file for cvdr: ${CVDR_CONFIG_PATH}"
    if [ ! -f "${CVDR_PATH}" ]; then
        echo "Cannot find cvdr from ${CVDR_PATH}"
        exit 1
    fi
    if [ ! -f "${CVDR_CONFIG_PATH}" ]; then
        echo "Cannot find configuration file of cvdr from ${CVDR_CONFIG_PATH}"
        exit 1
    fi
}

function cvdr() {
    HOME=${PWD} CVDR_USER_CONFIG_PATH=${CVDR_CONFIG_PATH} ${CVDR_PATH} "$@"
}


function verify_adb_connection() {
  # TODO(b/448209030): Retrieve serial of the device from the output of cvdr list.
  local cvdr_create_output="${1}"
  adb_serial=$(echo -e "${cvdr_create_output}" | grep "ADB:" | grep -oE "[^ ]+$")
  if [[ -z "${adb_serial}" ]]; then
    echo "Device is not adb connected"
    exit 1
  fi
  timeout 30s adb -s ${adb_serial} wait-for-device
}
