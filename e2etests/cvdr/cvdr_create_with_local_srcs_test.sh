#!/bin/bash

set -e -x
source ${TEST_SRCDIR}/_main/cvdr/common_utils.sh
validate_components

CVD_HOST_PKG="${TEST_SRCDIR}/+git_repository+aosp_artifact/cvd-host_package.tar.gz"
if [ ! -f ${CVD_HOST_PKG} ]; then
    echo "Cannot find CVD host package from ${CVD_HOST_PKG}"
    exit 1
fi
IMAGE_ZIP="${TEST_SRCDIR}/+git_repository+aosp_artifact/images.zip"
if [ ! -f "${IMAGE_ZIP}" ]; then
    echo "Cannot find image zip file from ${IMAGE_ZIP}"
    exit 1
fi

SERVICE=$(cvdr get_config user_default_service || cvdr get_config system_default_service)
SERVICE_URL=$(cvdr get_config "services[\"$SERVICE\"].service_url")

HOSTNAME=$(cvdr host create)
cleanup() {
    cvdr host delete ${HOSTNAME}
}
trap cleanup EXIT

out=$(cvdr create \
  --host=${HOSTNAME} \
  --local_cvd_host_pkg_src=${CVD_HOST_PKG} \
  --local_images_zip_src=${IMAGE_ZIP})

verify_adb_connection "${out}"
