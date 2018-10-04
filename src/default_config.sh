# GCP Account
GCLOUD_CONFIG_NAME=""

# Firewall
FIREWALL_NAME=""
FIREWALL_TAG=""
FIREWALL_OPEN_PORT=""

# Instance
INSTANCE_NAME=""
MACHINE_TYPE="n1-standard-4" # "n1-highcpu-8" "n1-standard-8" "f1-micro"
MACHINE_IMAGE=""
DISK_SIZE="10" # GB
DISK_TYPE="pd-standard"
ZONE="us-west1-a"
PREEMPTIBLE=1

# start.sh プロセス終了時に docker-machine を落とすかどうか
SHUTDOWN_ON_PROCESS_EXIT=0

# Commands
GCLOUD_BIN="gcloud"
DOCKER_MACHINE_BIN="docker-machine"
WATCHMEDO_BIN="watchmedo"
RSYNC_BIN="rsync"

# Sync
LOGIN_USERNAME="docker-user"
SYNC_FROM=""
SYNC_TO=""
SYNC_OPTION='' # for rsync
SYNC_INTERVAL=5
IGNORE_CHANGE='' # for watchdog (should match full path)
SYNC_LOG=/tmp/sync_log.txt


function on_start {
    # サーバ起動時にローカルで実行するコマンド
    # do_ssh "mkdir -p /tmp/hoge" でリモートサーバに対してコマンド実行可能
    # rsync, scp, ssh で直接ホストを指定する場合は "$LOGIN_USERNAME@$REMOTE_HOST" で接続可能
    :
}

function on_sync {
    # ファイルの転送が完了するたびに実行するコマンド
    # $SYNC_LOG ファイルに前回以降に同期されたファイルのリストが記載されている
    # rsync, scp, ssh で直接ホストを指定する場合は "$LOGIN_USERNAME@$REMOTE_HOST" で接続可能
    :
}

function on_create {
    # サーバ作成時にローカルで実行するコマンド
    # do_ssh "mkdir -p /tmp/hoge" のような形でリモートサーバに対してコマンド実行可能
    # rsync, scp, ssh で直接ホストを指定する場合は "$LOGIN_USERNAME@$REMOTE_HOST" で接続可能
    :
}