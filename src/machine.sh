#!/usr/bin/env bash

set -eu

script_dir_path=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

. "$script_dir_path/init_script.sh"

function boot {

    local docker_machine_exists=$([ $(${DOCKER_MACHINE_BIN} ls --filter="name=^${INSTANCE_NAME}$" | wc -l) -ne 2 ]; echo $?)
    local gce_instance_exists=$([ $(${GCLOUD_BIN} compute instances list --filter="${INSTANCE_NAME}" 2>/dev/null | wc -l) -ne 2 ]; echo $?)

    if [ "$docker_machine_exists" ]; then
        set +e
        local machine_config=$(${DOCKER_MACHINE_BIN} config ${INSTANCE_NAME} 2>&1)
        set -e
        if echo "$machine_config" | grep -e "The resource.*instances/${INSTANCE_NAME}.*was not found"; then
            ${DOCKER_MACHINE_BIN} rm ${INSTANCE_NAME}
            docker_machine_exists=0
        fi
    fi

    if [ "$docker_machine_exists" -ne "$gce_instance_exists" ]; then
        echo ""
        if [ "$docker_machine_exists" -eq 1 ]; then
            echo "--- Inconsistency error ---"
            echo "Docker machine instance (${INSTANCE_NAME}) already exists but GCE instance doesn't."
            echo "You might have changed GCLOUD_CONFIG_NAME after creating the last instance."
            echo "Please check GCLOUD_CONFIG_NAME in ${CONFIG_FILENAME} and follow either step below."
            echo "  - change the INSTANCE_NAME in ${CONFIG_FILENAME}"
            echo "  - remove the docker machine instance"
        else
            echo "--- Inconsistency error ---"
            echo "GCE instance (${INSTANCE_NAME}) already exists but Docker Machine doesn't."
            echo "You might have changed GCLOUD_CONFIG_NAME after creating the last instance."
            echo "Please check GCLOUD_CONFIG_NAME in ${CONFIG_FILENAME} and follow either step below."
            echo "  - change the INSTANCE_NAME in ${CONFIG_FILENAME}"
            echo "  - remove the GCE instance"
        fi
        exit 1
    fi

    if [ "${docker_machine_exists}" -eq 1 ] ; then
        if [ "$(${DOCKER_MACHINE_BIN} status "${INSTANCE_NAME}")" = "Stopped" ] ; then
            # start instance
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
        MACHINE_IMAGE_OPTION=""
        if [ "${MACHINE_IMAGE}" != "" ]; then
            image=$(gcloud compute images list --uri | grep "${MACHINE_IMAGE}" | tail -n 1)
            if [ "${image}" == "" ]; then
                echo "Error unknown MACHINE_IMAGE: ${MACHINE_IMAGE}"
                exit 1
            fi
            echo "Using machine image: ${image}"
            MACHINE_IMAGE_OPTION="--google-machine-image=${image}"
        fi
        # create instance
        "$DOCKER_MACHINE_BIN" create --driver=google \
        --google-project=${PROJECT_ID} \
        ${PREEMPTIBLE_OPTION} \
        --google-machine-type=${MACHINE_TYPE} \
        ${MACHINE_IMAGE_OPTION} \
        --google-disk-size=${DISK_SIZE} \
        --google-disk-type=${DISK_TYPE} \
        --google-zone=${ZONE} \
        ${TAG_OPTION} \
        ${INSTANCE_NAME}

        "$GCLOUD_BIN" compute config-ssh

        on_create
    fi

    IP_ADDRESS=$(docker-machine ls -f "{{.Name}}\t{{.URL}}" | cut -f2 | sed 's/tcp:\/\///' | sed 's/:[0-9]\+//')

}

function stop {

    "$DOCKER_MACHINE_BIN" stop "${INSTANCE_NAME}"

}

function assert_running {
    local status
    local failed
    status="$(${DOCKER_MACHINE_BIN} status "${INSTANCE_NAME}")"
    failed=$?

    if [ "$failed" -ne 0 ]; then
        exit $failed
    fi

    if [ "$status" != "Running" ]; then
        echo -e "\nInstance [$INSTANCE_NAME] is not running. Run following command.\n\nrboot -c $CONFIG_FILENAME" >&2
        exit 1
    fi
}

function remove {

    "$DOCKER_MACHINE_BIN" rm "${INSTANCE_NAME}"

}