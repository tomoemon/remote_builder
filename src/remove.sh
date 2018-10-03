#!/bin/bash

set -eu

script_dir_path=$(cd "$(dirname "$0")"; pwd)

. "$script_dir_path/init_script.sh"

"$DOCKER_MACHINE_BIN" rm "${INSTANCE_NAME}"