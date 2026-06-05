#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: bash scripts/train_lerf_12gb.sh <scene> <gpu_id> [iterations]"
  echo "Example: bash scripts/train_lerf_12gb.sh figurines 0 7000"
  exit 1
fi

SCENE="$1"
GPU_ID="$2"
ITERATIONS="${3:-7000}"

PROJECT_DIR="${PROJECT_DIR:-$HOME/3DGS}"
GG_DIR="${GG_DIR:-$PROJECT_DIR/third_party/gaussian-grouping}"

if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
  source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
  source "$HOME/anaconda3/etc/profile.d/conda.sh"
else
  eval "$(conda shell.bash hook)"
fi

set +u
conda activate gaussian_grouping
set -u
source "$PROJECT_DIR/scripts/env_gaussian_grouping.sh"

cd "$GG_DIR"
mkdir -p "$PROJECT_DIR/logs"

CUDA_VISIBLE_DEVICES="$GPU_ID" python train.py \
  -s "data/lerf/$SCENE" \
  -r 1 \
  -m "output/lerf/$SCENE" \
  --config_file "$PROJECT_DIR/configs/gaussian_grouping/train_12gb.json" \
  --train_split \
  --iterations "$ITERATIONS" \
  --test_iterations 1000 "$ITERATIONS" \
  --save_iterations 1000 "$ITERATIONS" \
  2>&1 | tee "$PROJECT_DIR/logs/train_${SCENE}_${ITERATIONS}_12gb.log"
