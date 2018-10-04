#!/bin/bash

set -eu

script_dir_path=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

. "$script_dir_path/init_script.sh"

"$DOCKER_MACHINE_BIN" rm "${INSTANCE_NAME}"