#!/bin/bash

set -euo pipefail

die() {
    echo >&2 "ERROR: $@"
    exit 1
}

cluster_type=$(cat cluster-type)

if [[ $cluster_type == "multi-region" ]]
then
    if [[ $(ps aux | grep [t]unnel | wc -l) -eq 0 ]]
    then
        die "it looks like tunnels have not been started yet for this multi-region cluster. on the external provisioning machine, once all regions have been provisioned, execute multi-start."
    fi
fi

echo "trying to start constellation and quorum..."

./.start-constellation
sleep 30
./.start-quorum $1
