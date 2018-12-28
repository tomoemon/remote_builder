#!/usr/bin/env bash

function usage_exit {
    {
        local command_name=$(basename $0)
        cat <<EOD
$command_name

Usage: $command_name [-c CONFIG_FILE]

Options
-c config filename (envvar REMOTE_CONFIG_FILE)
EOD
    } 1>&2
    exit 1
}

while getopts c:h OPT
do
    case $OPT in
        c)  CONFIG_FILENAME=$OPTARG
            ;;
        h)  usage_exit
            ;;
        \?) usage_exit
            ;;
    esac
done

if [ ! -v CONFIG_FILENAME ]; then
    if [ -v REMOTE_CONFIG_FILE ]; then
        CONFIG_FILENAME=$REMOTE_CONFIG_FILE
    else
        usage_exit
    fi
fi

shift $((OPTIND - 1))