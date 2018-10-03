#!/bin/bash

set -eu

: $1

script_dir_path=$(cd "$(dirname "$0")"; pwd)
. "$script_dir_path/default_config.sh"
. "$1"
. "$script_dir_path/check_env.sh"

REMOTE_HOST=$(grep $INSTANCE_NAME ~/.ssh/config | cut -d' ' -f2)

if ! ( "$GCLOUD_BIN" config configurations list | grep "${GCLOUD_CONFIG_NAME}"  | grep True >/dev/null); then
    if ! ("$GCLOUD_BIN" config configurations activate "${GCLOUD_CONFIG_NAME}"); then
        echo ""
        echo "Configure GCP account before you start. See below steps."
        echo "  $GCLOUD_BIN config configurations create {CONFIG_NAME}"
        echo "  $GCLOUD_BIN config configurations activate {CONFIG_NAME}"
        echo "  $GCLOUD_BIN config set account {YOUR_ACCOUT}"
        echo "  $GCLOUD_BIN config set project {YOUR_PROJECT_ID}"
        echo ""
        echo "and then write your {CONFIG_NAME} to config.sh (eg. GCLOUD_CONFIG_NAME=myconfig)"
        exit 1
    fi
fi

if ! ("$GCLOUD_BIN" auth application-default print-access-token >/dev/null); then
    "$GCLOUD_BIN" auth application-default login
fi

function do_ssh {
    set -eu
    : $1
    "$GCLOUD_BIN" compute ssh "${LOGIN_USERNAME}@${INSTANCE_NAME}" --zone ${ZONE} --command "$1"
}
