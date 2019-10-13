#!/bin/bash

set -euo pipefail

sudo docker ps --no-trunc | grep geth | grep -v attach | awk '{print $1}' | xargs sudo docker inspect -f '' | jq -r '.[0].LogPath' | xargs sudo tail -f | jq -r '.log | rtrimstr("\n")'
