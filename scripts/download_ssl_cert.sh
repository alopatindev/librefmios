#!/bin/bash

HOST="${1}"
PORT=443

if [[ "${HOST}" == "" ]]; then
    echo "usage $0 hostname"
    exit 1
fi

openssl s_client \
    -showcerts -connect "${HOST}:${PORT}" </dev/null 2>/dev/null | \
openssl x509 -outform DER >"../resources/${HOST}.der"
