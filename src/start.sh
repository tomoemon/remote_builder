#!/bin/bash

set -eu

cwd="$(pwd)"
script_dir_path=$(cd "$(dirname "$0")"; pwd)

. "$script_dir_path/init_script.sh"

echo "Your active configuration is [${GCLOUD_CONFIG_NAME}]"

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

set +e
status=$(docker-machine status "${INSTANCE_NAME}")
exists=$?
set -e
if [ $exists -eq 0 ] ; then
    if [ "$status" = "Stopped" ] ; then
        : start instance
        "$DOCKER_MACHINE_BIN" start "${INSTANCE_NAME}"
        # IP アドレスが変わっている可能性がある
        "$GCLOUD_BIN" compute config-ssh
        "$DOCKER_MACHINE_BIN" regenerate-certs --force "${INSTANCE_NAME}"
    else
        : instance is already running
    fi
else
    : create instance
    "$DOCKER_MACHINE_BIN" create --driver=google \
    --google-project=${PROJECT_ID} \
    --google-preemptible \
    --google-machine-type=${MACHINE_TYPE} \
    --google-disk-size=${DISK_SIZE} \
    --google-disk-type=pd-standard \
    --google-zone=${ZONE} \
    --google-tags=${FIREWALL_TAG} \
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
. "$script_dir_path/sync_all.sh"

# 起動時処理を行う
on_start; cd "${cwd}"

# ファイルの同期を開始する
bash "$script_dir_path/sync_loop.sh" "$1" &

# ファイル更新の監視を開始する
"$WATCHMEDO_BIN" shell-command -R -W \
  --command 'date +%s > /tmp/latest_update_time.txt; echo ${watch_src_path} was changed' ${SYNC_FROM} \
  -i "${IGNORE_CHANGE}" &

wait