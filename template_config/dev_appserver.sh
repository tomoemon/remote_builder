# glouc config configurations activate で使用可能な config の名前
# default のままでも問題はないが、このワークスペースを作るための設定を別に管理することをオススメ
GCLOUD_CONFIG_NAME="default"

# GCE 上でのインスタンス名
INSTANCE_NAME="my-workspace"

# GCE 上でのファイアウォールの名前（空の場合はファイアウォールを作成しない）
# ssh/scp/rsync だけできれば良い場合はファイアウォールの設定は不要
FIREWALL_NAME="default-allow-dev-appserver"

# GCE 上でこのネットワークタグが付いているものにファイアウォールを適用する
FIREWALL_TAG="dev-app-server"

# このファイアウォールが開ける内向きのポート
FIREWALL_OPEN_PORT="8000-9000"

# 転送元のディレクトリ
SYNC_FROM=""

# 転送先のディレクトリ
SYNC_TO=""

# SYNC_FROM から SYNC_TO に転送する際の rsync の転送オプション
# eg. dot files, dot directories を転送しない 
SYNC_OPTION='--exclude ".*"' # for rsync

# SYNC_FROM 内でファイルの変更を検知するためのオプション
# rsync と watchmedo で大きく書き方が異なるため、別のオプションで指定する
#
# 内部仕様
# watchmedo がファイル変更イベントを検知するたびに rsync を起動するため、
# SYNC_OPTION に exclude の記載があれば IGNORE_CHANGE は空でも余計なファイル転送は発生しない
# ただし、rsync を起動して変更チェックをする分の負荷は発生する
# eg. dot files, dot directories の変更を検知しない
IGNORE_CHANGE='*/.*;*/.*/*' # for watchdog (should match full path)


function on_start {
    # サーバ立ち上げ時にローカルで実行するコマンド
    # dev_appserver を起動する等
    :
}
