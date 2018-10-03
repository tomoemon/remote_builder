#!/bin/bash

set -eu

cwd="$(pwd)"
script_dir_path=$(cd "$(dirname "$0")"; pwd)

. "$script_dir_path/init_script.sh"
. "$script_dir_path/sync.sh"

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

set +e
status=$(${DOCKER_MACHINE_BIN} status "${INSTANCE_NAME}")
exists=$?
set -e
if [ $exists -eq 0 ] ; then
    if [ "$status" = "Stopped" ] ; then
        : start instance
        "$DOCKER_MACHINE_BIN" start "${INSTANCE_NAME}"
        # 再起動すると IP アドレスが変わるため ssh に関する設定を更新する必要がある
        "$GCLOUD_BIN" compute config-ssh
        "$DOCKER_MACHINE_BIN" regenerate-certs --force "${INSTANCE_NAME}"
    fi
else
    PREEMPTIBLE_OPTION="--google-preemptible"
    if [ "${PREEMPTIBLE}" != "1" ]; then
        PREEMPTIBLE_OPTION=""
    fi
    TAG_OPTION=""
    if [ "${FIREWALL_NAME}" != "" ] && [ "${FIREWALL_TAG}" != "" ]; then
        TAG_OPTION="--google-tags=${FIREWALL_TAG}"
    fi
    : create instance
    "$DOCKER_MACHINE_BIN" create --driver=google \
    --google-project=${PROJECT_ID} \
    ${PREEMPTIBLE_OPTION} \
    --google-machine-type=${MACHINE_TYPE} \
    --google-disk-size=${DISK_SIZE} \
    --google-disk-type=${DISK_TYPE} \
    --google-zone=${ZONE} \
    ${TAG_OPTION} \
    ${INSTANCE_NAME}

    "$GCLOUD_BIN" compute config-ssh

    on_create; cd "${cwd}"
fi

IP_ADDRESS=$(docker-machine ls -f "{{.Name}}\t{{.URL}}" | cut -f2 | sed 's/tcp:\/\///' | sed 's/:[0-9]\+//')

function on_process_exit {
    kill $(jobs -p)
    sleep 5
    if [ "${SHUTDOWN_ON_PROCESS_EXIT}" -eq 1 ]; then
        sleep 5
        "$DOCKER_MACHINE_BIN" stop "${INSTANCE_NAME}"
    fi
}

# このスクリプト終了時に
# - バックグラウンドプロセスを終了
# - リモートサーバをシャットダウン
trap "on_process_exit" EXIT

# 初回の同期
sync_all

# 起動時処理を行う
on_start; cd "${cwd}"

# ファイルの同期を開始する
sync_loop &

# ファイル更新の監視を開始する
"$WATCHMEDO_BIN" shell-command -R -W \
  --command 'date +%s > /tmp/latest_update_time.txt; echo ${watch_src_path} was changed' ${SYNC_FROM} \
  -i "${IGNORE_CHANGE}" &

wait