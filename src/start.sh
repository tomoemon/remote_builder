#!/usr/bin/env bash

set -eu

script_dir_path=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

. "$script_dir_path/init_script.sh"
. "$script_dir_path/machine.sh"
. "$script_dir_path/sync.sh"

function on_process_exit {
    kill $(jobs -p)
    sleep 5
    if [ "${SHUTDOWN_ON_PROCESS_EXIT}" -eq 1 ]; then
        sleep 5
        "$DOCKER_MACHINE_BIN" stop "${INSTANCE_NAME}"
    fi
}

function start {

    if [ "${FIREWALL_NAME}" != "" ] && [ "${FIREWALL_TAG}" != "" ]; then
        if ! ("$GCLOUD_BIN" compute firewall-rules list --format="table(name)" | grep ${FIREWALL_NAME} >/dev/null); then
            # add firewall
            "$GCLOUD_BIN" compute --project=${PROJECT_ID} firewall-rules create ${FIREWALL_NAME} \
            --direction=INGRESS \
            --priority=1000 \
            --network=default \
            --action=ALLOW \
            --rules=tcp:${FIREWALL_OPEN_PORT} \
            --source-ranges=0.0.0.0/0 \
            --target-tags=${FIREWALL_TAG}
        fi
    fi

    # インスタンスの起動 or 構築）
    boot

    # このスクリプト終了時に
    # - バックグラウンドプロセスを終了
    # - リモートサーバをシャットダウン
    trap "on_process_exit" EXIT

    # 初回の同期
    sync_all

    # 起動時処理を行う
    on_start

    # ファイルの同期を開始する
    sync_loop &

    wait
}