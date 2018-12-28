#!/usr/bin/env bash

set -eu

script_dir_path=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
. "$script_dir_path/init_script.sh"

DATE_FORMAT="+%s.%N"

function sync_all {
    set -eu

    do_ssh "mkdir -p ${SYNC_TO}"
    date "${DATE_FORMAT}" > /tmp/last_rsync_start_time.txt
    eval "$RSYNC_BIN" -aui $SYNC_OPTION "${SYNC_FROM}" ${LOGIN_USERNAME}@${REMOTE_HOST}:${SYNC_TO} | cut -d' ' -f2
}

function sync_loop {
    set -eu

    trap 'kill $(jobs -p)' EXIT

    # ファイル更新の監視を開始する
    echo "0" > /tmp/latest_update_time.txt

    "$WATCHMEDO_BIN" shell-command -R -W \
        --command "date ${DATE_FORMAT}"'> /tmp/latest_update_time.txt; echo ${watch_src_path} was changed' ${SYNC_FROM} \
        -i "${IGNORE_CHANGE}" &

    do_ssh "mkdir -p ${SYNC_TO}"

    while :
    do
        update_time=$(cat /tmp/latest_update_time.txt)
        last_rsync_time=$(cat /tmp/last_rsync_start_time.txt)

        updated=$(echo "$update_time" "$last_rsync_time" | awk -e '{ printf("%d",$1>$2) }')
        # 前回の rsync 開始時以降にファイル更新が発生したら
        if [ "$updated" -eq 1 ]; then
            # 前回の rsync 開始時から interval 秒経過したら
            current_time=$(date "${DATE_FORMAT}")
            interval=$(echo "$current_time" "$last_rsync_time" "$SYNC_INTERVAL" | awk -e '{ printf("%d",($1-$2)>=$3) }')
            if [ "$interval" -eq 1 ]; then
                echo $current_time > /tmp/last_rsync_start_time.txt
                eval "$RSYNC_BIN" -aui $SYNC_OPTION "${SYNC_FROM}" ${LOGIN_USERNAME}@${REMOTE_HOST}:${SYNC_TO} | cut -d" " -f2 | tee "${SYNC_LOG}"
                on_sync
            fi
        fi
        sleep 1
    done
}