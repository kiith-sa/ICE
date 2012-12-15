#!/bin/bash

DATA_DIR='/usr/local/share/ice-game'

if [ "$(whoami)" != "root" ]; then
    echo "This script requires root priviledges; use as root or use sudo."
    exit 1
fi

rm -rf $DATA_DIR

echo 'Done.'
