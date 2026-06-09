#!/bin/bash
set -eo pipefail

source "$(dirname "$0")/common_utils.sh"

validate_components

CVD_HOST_PKG="${TEST_SRCDIR}/+git_repository+aosp_artifact/cvd-host_package.tar.gz"
if [ ! -f "${CVD_HOST_PKG}" ]; then
    echo "Cannot find cvd host package from ${CVD_HOST_PKG}"
    exit 1
fi
IMAGE_ZIP="${TEST_SRCDIR}/+git_repository+aosp_artifact/images.zip"
if [ ! -f "${IMAGE_ZIP}" ]; then
    echo "Cannot find image zip file from ${IMAGE_ZIP}"
    exit 1
fi

HOSTNAME=$(cvdr host create)
trap 'cleanup' EXIT
function cleanup {
  cvdr host delete "${HOSTNAME}"
}

cvdr create   --host="${HOSTNAME}"   --local_cvd_host_pkg_src="${CVD_HOST_PKG}"   --local_images_zip_src="${IMAGE_ZIP}"

echo "=== Verifying initial cvdr list output ==="
LIST_OUT=$(cvdr list)
echo "${LIST_OUT}"

if ! echo "${LIST_OUT}" | grep -A 6 "Host: ${HOSTNAME}" | grep -q "ADB: 127.0.0.1:"; then
  echo "FAIL: cvdr list did not show active ADB connection after create"
  exit 1
fi

echo "=== Stopping device on ${HOSTNAME} (group: cvd_1, name: 1) ==="
cvdr stop --host="${HOSTNAME}" --group=cvd_1 --name=1

echo "Sleeping 10s for forwarder data channels to teardown..."
sleep 10

echo "=== Verifying post-stop cvdr list output ==="
LIST_OUT_STOP=$(cvdr list)
echo "${LIST_OUT_STOP}"

HOST_BLOCK=$(echo "${LIST_OUT_STOP}" | grep -A 6 "Host: ${HOSTNAME}")
echo "=== Target Host Block ==="
echo "${HOST_BLOCK}"

if echo "${HOST_BLOCK}" | grep -q "ADB: 127.0.0.1:"; then
  echo "FAIL: cvdr list incorrectly retained stale ADB IP:Port after device shutdown (Bug 499084052 unaligned!)"
  exit 1
fi

if ! echo "${HOST_BLOCK}" | grep -q -E "ADB: (stopped|failed|not connected)"; then
  echo "FAIL: cvdr list did not transition to stopped, failed, or not connected state"
  exit 1
fi

echo "SUCCESS: Bug 499084052 state transition verified hermetically!"
