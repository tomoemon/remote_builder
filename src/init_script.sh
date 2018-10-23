#!/bin/bash

set -eu

if [ ! -v __inited ]; then

    script_dir_path=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
    . "$script_dir_path/options.sh"
    . "$script_dir_path/default_config.sh"
    . "$CONFIG_FILENAME"
    . "$script_dir_path/check_env.sh"

    REMOTE_HOST=$(grep $INSTANCE_NAME ~/.ssh/config | cut -d' ' -f2)

    if ! ( "$GCLOUD_BIN" config configurations list --filter="NAME=${GCLOUD_CONFIG_NAME}" --format="table(is_active)" | grep True >/dev/null); then
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

    PROJECT_ID=$(gcloud config get-value project)

    # see: https://qiita.com/shin1ogawa/items/49a076f62e5f17f18fe5
    default_credential_account=$(curl -sS "https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=$(gcloud auth application-default print-access-token)" | tr -d " " | grep '"email"' | cut -d':' -f2 | sed 's/[",]//g')
    gcloud_active_account=$(gcloud config list --format="table(core.account)" | tail -n +2)

    if [ "$default_credential_account" != "$gcloud_active_account" ]; then
        echo ""
        echo "Your application default credentials doesn't match your active account."
        "$GCLOUD_BIN" auth application-default login
    fi

    function do_ssh {
        set -eu
        : $1
        "$GCLOUD_BIN" compute ssh "${LOGIN_USERNAME}@${INSTANCE_NAME}" --zone ${ZONE} --command "$1"
    }

    __inited=1

fi