#!/bin/bash

set -euo pipefail

cluster_type=$(cat cluster-type)

if [[ $cluster_type == "multi-region" ]]
then
    echo "not starting this multi-region cluster yet. all regions need to be provisioned, tunnels need to be set up, and then ./start can be run on each node"
else
    echo "starting this single-region cluster"
    ./start "$1"
fi
