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

config=$(mktemp)

cat > ${config} << EOF
{
    "instances": [{
            "@import": "phone",
            "vm": {
                "memory_mb": 8192,
                "setupwizard_mode": "OPTIONAL",
                "cpus": 4
            },
            "disk": {
                "default_build": "@ab/aosp-android-latest-release/aosp_cf_x86_64_only_phone-userdebug",
                "download_img_zip": true
            }
        }
    ]
}
EOF

out=$(cvdr create --host=${HOSTNAME} ${config})

verify_adb_connection "${out}"
