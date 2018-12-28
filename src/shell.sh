#!/usr/bin/env bash

set -eu

script_dir_path=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

. "$script_dir_path/init_script.sh"

function shell {

    eval $("$DOCKER_MACHINE_BIN" env "${INSTANCE_NAME}")

    eval $@

}