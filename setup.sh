#!/bin/bash

set -e

# artemis-version e.g. 2.28.0
ARTEMIS_VERSION="$1"

BASE_TMPDIR="artemis"

ARTEMIS_DIST_DIR="${BASE_TMPDIR}/${ARTEMIS_VERSION}"

function main(){
    download_and_unpack_artemis
    create_master_slave
    create_replica
}

function download_and_unpack_artemis(){
    # Prepare directory
    if [ ! -d "${ARTEMIS_DIST_DIR}" ]; then
        echo "Creating ${ARTEMIS_DIST_DIR}"
        mkdir -p "${ARTEMIS_DIST_DIR}"
    elif [ ! -z "$(find "${BASE_TMPDIR}" -name "${ARTEMIS_VERSION}" -type d -mmin +60)" ]; then
        echo "Cleaning up ${ARTEMIS_DIST_DIR}"
        rm -rf ${ARTEMIS_DIST_DIR}/*
    else
        echo "Using ${ARTEMIS_DIST_DIR}"
    fi

    # Check if the release is already available locally, if not try to download it
    if [ -z "$(ls -A ${ARTEMIS_DIST_DIR})" ]; then
        CDN="$(curl -s https://www.apache.org/dyn/closer.cgi\?preferred=true)activemq/activemq-artemis/${ARTEMIS_VERSION}/"
        ARCHIVE="https://archive.apache.org/dist/activemq/activemq-artemis/${ARTEMIS_VERSION}/"
        ARTEMIS_BASE_URL=${CDN}
        ARTEMIS_DIST_FILE_NAME="apache-artemis-${ARTEMIS_VERSION}-bin.tar.gz"
        CURL_OUTPUT="${ARTEMIS_DIST_DIR}/${ARTEMIS_DIST_FILE_NAME}"

        # Fallback to the Apache archive if the version doesn't exist on the CDN anymore
        if [ -z "$(curl -Is ${ARTEMIS_BASE_URL}${ARTEMIS_DIST_FILE_NAME} | head -n 1 | grep 200)" ]; then
            ARTEMIS_BASE_URL=${ARCHIVE}

            # If the archive also doesn't work then report the failure and abort
            if [ -z "$(curl -Is ${ARTEMIS_BASE_URL}${ARTEMIS_DIST_FILE_NAME} | head -n 1 | grep 200)" ]; then
            echo "Failed to find ${ARTEMIS_DIST_FILE_NAME}. Tried both ${CDN} and ${ARCHIVE}."
            exit 1
            fi
        fi

        echo "Downloading ${ARTEMIS_DIST_FILE_NAME} from ${ARTEMIS_BASE_URL}..."
        curl --progress-bar "${ARTEMIS_BASE_URL}${ARTEMIS_DIST_FILE_NAME}" --output "${CURL_OUTPUT}"

        echo "Expanding ${ARTEMIS_DIST_DIR}/${ARTEMIS_DIST_FILE_NAME}..."
        tar xzf "$CURL_OUTPUT" --directory "${ARTEMIS_DIST_DIR}" --strip 1

        echo "Removing ${ARTEMIS_DIST_DIR}/${ARTEMIS_DIST_FILE_NAME}..."
        rm -rf "${ARTEMIS_DIST_DIR}"/"${ARTEMIS_DIST_FILE_NAME}"
    fi
}

function create_master_slave(){
    mkdir -p brokers/masterslave
    cwd=$(pwd)
    cd artemis/${ARTEMIS_VERSION}/bin
    echo "create master node"
    ./artemis create --name master --no-stomp-acceptor --require-login --user artemis --password artemis  ../../../brokers/masterslave/master
    echo "create slave node"
    ./artemis create --name slave --no-stomp-acceptor --require-login --no-web --user artemis --password artemis  ../../../brokers/masterslave/slave
    cd $cwd

    # enhance default config
    cd brokers/masterslave/master/etc
    # remove last two lines, so that additional config can be added
    sed -i '$ d' broker.xml
    sed -i '$ d' broker.xml
    # append master config
    cat ../../../../templates/master-slave/master.xml >> broker.xml

    cd $cwd

    cd brokers/masterslave/slave/etc
    # remove last two lines, so that additional config can be added
    sed -i '$ d' broker.xml
    sed -i '$ d' broker.xml
    # append master config
    cat ../../../../templates/master-slave/slave.xml >> broker.xml

    cd $cwd

}

function create_replica(){
    mkdir -p brokers/replica
    cwd=$(pwd)
    cd artemis/${ARTEMIS_VERSION}/bin
    echo "create master node"
    ./artemis create --name replica01 --no-stomp-acceptor --require-login --user artemis --password artemis --no-hornetq-acceptor --no-amqp-acceptor ../../../brokers/replica/replica01
    echo "create slave node"
    ./artemis create --name replica02 --no-stomp-acceptor --require-login --no-web --user artemis --password artemis --no-hornetq-acceptor --no-amqp-acceptor --port-offset 1 ../../../brokers/replica/replica02
    cd $cwd

    # enhance default config
    cd brokers/replica/replica01/etc
    # remove last two lines, so that additional config can be added
    sed -i '$ d' broker.xml
    sed -i '$ d' broker.xml
    # append master config
    cat ../../../../templates/replica/replica01.xml >> broker.xml

    cd $cwd

    cd brokers/replica/replica02/etc
    # remove last two lines, so that additional config can be added
    sed -i '$ d' broker.xml
    sed -i '$ d' broker.xml
    # append master config
    cat ../../../../templates/replica/replica02.xml >> broker.xml

    cd $cwd
}

main