#!/bin/bash

set -e

source ./vars

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ $1 == "" ]]; then
    echo "You must specify \"full\" or \"incremental\" as the first argument"
    exit 1
fi

if [[ $1 == "remove-all-but-n-full" ]]; then
    if [[ $2 == "" ]]; then
        echo "You must specify a number if using \"remove-all-but-n-full\""
        exit 1;
    fi
    num=$2
fi

if [[ $1 == "restore" ]]; then
    if [[ $2 == "" ]]; then
        echo "You must specify a restore target directory if using \"restore\""
        exit 1;
    fi
    target=$2
fi

type=$1

for location in "${!backup[@]}"; do

    if [ $type == "full" -o $type == "incremental" ]; then
        echo "Backing up ${backup["$location"]} to $location"
        $duplicity $type \
            "${backup["$location"]}" \
            "b2://${account}@${bucket}/${location}" | \
            while read f; do
                echo $location: $f;
            done &
    fi

    if [[ $type == "cleanup" ]]; then
        echo "Cleaning up $location"
        $duplicity $type "b2://${account}@${bucket}/${location} $2"
    fi

    if [[ $type == "verify" ]]; then
        echo "Verifying $location"
        $duplicity $type "b2://${account}@${bucket}/${location}" "${backup["$location"]}"
    fi

    if [[ $type == "remove-all-but-n-full" ]]; then
        echo "Removing all but $num from $location"
        $duplicity $type $num --force "b2://${account}@${bucket}/${location}"
    fi

    if [[ $type == "restore" ]]; then
        echo "Restoring $location to ${target}/${backup["$location"]}"
        mkdir -p $(dirname ${target}/${backup["$location"]})
        $duplicity $type \
            "b2://${account}@${bucket}/${location}" \
            "${target}/${backup["$location"]}" | \
            while read f; do
                echo $location: $f;
            done &
    fi

done

wait
