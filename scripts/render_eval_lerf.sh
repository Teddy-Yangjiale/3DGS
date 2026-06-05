#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: bash scripts/render_eval_lerf.sh <scene> <gpu_id> [iteration]"
  echo "Example: bash scripts/render_eval_lerf.sh figurines 0 7000"
  exit 1
fi

SCENE="$1"
GPU_ID="$2"
ITERATION="${3:-7000}"

PROJECT_DIR="${PROJECT_DIR:-$HOME/3DGS}"
GG_DIR="${GG_DIR:-$PROJECT_DIR/third_party/gaussian-grouping}"

if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
  source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
  source "$HOME/anaconda3/etc/profile.d/conda.sh"
else
  eval "$(conda shell.bash hook)"
fi

conda activate gaussian_grouping
source "$PROJECT_DIR/scripts/env_gaussian_grouping.sh"

cd "$GG_DIR"
mkdir -p "$PROJECT_DIR/logs" result/lerf_mask

CUDA_VISIBLE_DEVICES="$GPU_ID" python render_lerf_mask.py \
  -m "output/lerf/$SCENE" \
  --skip_train \
  2>&1 | tee "$PROJECT_DIR/logs/render_lerf_mask_${SCENE}_${ITERATION}_12gb.log"

ln -sfn "$(pwd)/output/lerf/$SCENE/test/ours_${ITERATION}_text/test_mask" "result/lerf_mask/$SCENE"

python script/eval_lerf_mask.py "$SCENE" \
  2>&1 | tee "$PROJECT_DIR/logs/eval_${SCENE}_${ITERATION}_12gb.log"
