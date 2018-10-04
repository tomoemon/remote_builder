#!/bin/bash

set -eu

script_dir_path=$(cd "$(dirname "$0")"; pwd)

. "$script_dir_path/init_script.sh"

eval $("$DOCKER_MACHINE_BIN" env "${INSTANCE_NAME}")

shift

eval $@