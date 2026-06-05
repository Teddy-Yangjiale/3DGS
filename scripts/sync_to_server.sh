#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: bash scripts/sync_to_server.sh <account>"
  echo "Example: bash scripts/sync_to_server.sh teddy"
  exit 1
fi

ACCOUNT="$1"
SERVER="172.18.35.215"
REMOTE_DIR="/data2/${ACCOUNT}/3DGS"

rsync -avz --delete \
  --exclude ".git/" \
  --exclude "data/" \
  --exclude "outputs/" \
  --exclude "checkpoints/" \
  --exclude "logs/" \
  ./ "${ACCOUNT}@${SERVER}:${REMOTE_DIR}/"

echo "Synced code to ${ACCOUNT}@${SERVER}:${REMOTE_DIR}"

