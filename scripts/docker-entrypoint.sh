#!/bin/sh
set -eu

if [ "$#" -eq 0 ]; then
    set -- "${DEFAULT_APP:-MobilePlanner}"
fi

exec "$@"