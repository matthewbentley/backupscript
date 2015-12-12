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

type=$1

echo $duplicity

for location in "${!backup[@]}"; do

    if [ $type == "full" -o $type == "incremental" ]; then
        echo "Backing up ${backup["$location"]} to $location"
        $duplicity $type "${backup["$location"]}" "b2://${account}@${bucket}/${location}" &
    fi

    if [[ $type == "remove-all-but-n-full" ]]; then
        echo "Removing all but $num from $location"
        $duplicity $type $num --force "b2://${account}@${bucket}/${location}"
    fi

done

wait
