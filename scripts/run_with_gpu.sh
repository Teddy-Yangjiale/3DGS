#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: bash scripts/run_with_gpu.sh <gpu_id> <command...>"
  echo "Example: bash scripts/run_with_gpu.sh 0 python train.py -s data/lerf_mask/figurines -m outputs/figurines"
  exit 1
fi

GPU_ID="$1"
shift

export CUDA_VISIBLE_DEVICES="${GPU_ID}"
exec "$@"

