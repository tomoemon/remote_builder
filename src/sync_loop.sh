#!/bin/bash

set -eu

script_dir_path=$(cd "$(dirname "$0")"; pwd)
. "$script_dir_path/init_script.sh"

do_ssh "mkdir -p ${SYNC_TO}"

set +x

while :
do
    update_time=$(cat /tmp/latest_update_time.txt)
    last_rsync_time=$(cat /tmp/last_rsync_start_time.txt)

    # 前回の rsync 開始時以降にファイル更新が発生したら
    if [ "$update_time" -gt "$last_rsync_time" ] ; then
        # 前回の rsync 開始時から interval 秒経過したら
        current_time=$(date +%s)
        if [ $(($current_time - $last_rsync_time)) -ge $SYNC_INTERVAL ] ; then
            echo $current_time > /tmp/last_rsync_start_time.txt
            eval "$RSYNC_BIN" -aui $SYNC_OPTION "${SYNC_FROM}" ${LOGIN_USERNAME}@${REMOTE_HOST}:${SYNC_TO} | cut -d" " -f2 | tee "${SYNC_LOG}"
            on_sync
        fi
    fi
    sleep 1
done