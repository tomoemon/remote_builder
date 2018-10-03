#!/bin/bash

set -eu

script_dir_path=$(cd "$(dirname "$0")"; pwd)
. "$script_dir_path/init_script.sh"

do_ssh "mkdir -p ${SYNC_TO}"
date +%s > /tmp/last_rsync_start_time.txt
eval "$RSYNC_BIN" -aui $SYNC_OPTION "${SYNC_FROM}" ${LOGIN_USERNAME}@${REMOTE_HOST}:${SYNC_TO} | cut -d' ' -f2
