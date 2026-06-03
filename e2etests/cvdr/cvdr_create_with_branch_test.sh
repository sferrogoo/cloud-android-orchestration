#!/bin/bash

set -e -x
source ${TEST_SRCDIR}/_main/cvdr/common_utils.sh
validate_components

SERVICE=$(cvdr get_config user_default_service || cvdr get_config system_default_service)
SERVICE_URL=$(cvdr get_config "services[\"$SERVICE\"].service_url")

HOSTNAME=$(cvdr host create)
cleanup() {
    cvdr host delete ${HOSTNAME}
}
trap cleanup EXIT

out=$(cvdr create \
  --host=${HOSTNAME} \
  --branch=aosp-android-latest-release \
  --build_target=aosp_cf_x86_64_only_phone-userdebug)

verify_adb_connection "${out}"
