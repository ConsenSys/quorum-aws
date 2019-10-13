#!/bin/bash

set -euo pipefail

cd "${0%/*}"

terraform_root="$(dirname "$(pwd)")"
local_data_root="$terraform_root/$1"
cluster_size=$2

if [[ $3 == "raft" ]]
then
  echo "Initialized genesis in Raft Mode"
  exit 0
elif [[ $3 == "istanbul" ]]
then
  istanbul_tools_bin='../../dependencies/istanbul-tools/build/bin'

  # Gathering node keys
  nodekeys=""
  iterator="1"
  while [ $iterator -le ${cluster_size} ]
  do
    nodekey=$(cat $local_data_root/geth$iterator/geth/nodekey)
    nodekeys+=$nodekey
    nodekeys+=","
    iterator=$((iterator+1))
  done
  # Generating new genesis file
  ${istanbul_tools_bin}/istanbul reinit --quorum --nodekey ${nodekeys%?} > ${local_data_root}/genesis.json
  echo "Initialized genesis in Istanbul Mode"
else
  echo "Error: not a valid consensus algorithm. Choose istanbul or raft"
  exit 1
fi
