#!/bin/bash

set -eu

function command_exists {
    set -eu
    : $1 $2 $3
    if which "$2" >/dev/null; then
        :
    else
        echo -e "check $1...\e[31mnot found\e[m"
        if [ "$3" != "" ]; then
            echo "  => ${3}"
        fi
        result=1
    fi
}

result=0
command_exists gcloud "$GCLOUD_BIN" https://cloud.google.com/sdk/downloads?hl=JA
command_exists docker-machine "$DOCKER_MACHINE_BIN" https://docs.docker.com/machine/install-machine/
command_exists watchmedo "$WATCHMEDO_BIN" https://github.com/gorakhargosh/watchdog#installation
command_exists rsync "$RSYNC_BIN" ""

if ! (bash --version | grep "version 4" >/dev/null); then
    echo "check bash(version 4)...\e[31mnot found\e[m"
    result=1
fi

if [ "$result" -ne 0 ]; then
    echo -e "\nCheck failed. Install the commands above before you start."
    exit 1
fi