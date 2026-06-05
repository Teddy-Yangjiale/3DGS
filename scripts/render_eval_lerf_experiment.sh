#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "Usage: bash scripts/render_eval_lerf_experiment.sh <scene> <experiment> <gpu_id> <iteration>"
  echo "Example: bash scripts/render_eval_lerf_experiment.sh teatime densify1500_7000 0 7000"
  exit 1
fi

SCENE="$1"
EXPERIMENT="$2"
GPU_ID="$3"
ITERATION="$4"

PROJECT_DIR="${PROJECT_DIR:-$HOME/3DGS}"
GG_DIR="${GG_DIR:-$PROJECT_DIR/third_party/gaussian-grouping}"
OUTPUT_NAME="${SCENE}_${EXPERIMENT}"

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
mkdir -p "$PROJECT_DIR/logs" result/lerf_mask result/lerf_mask_trials

CUDA_VISIBLE_DEVICES="$GPU_ID" python render_lerf_mask.py \
  -m "output/lerf/$OUTPUT_NAME" \
  --skip_train \
  2>&1 | tee "$PROJECT_DIR/logs/render_lerf_mask_${OUTPUT_NAME}.log"

PRED_DIR="$(pwd)/output/lerf/$OUTPUT_NAME/test/ours_${ITERATION}_text/test_mask"
ln -sfn "$PRED_DIR" "result/lerf_mask_trials/$OUTPUT_NAME"

if [ -L "result/lerf_mask/$SCENE" ]; then
  readlink "result/lerf_mask/$SCENE" > "result/lerf_mask_trials/${SCENE}_previous_link.txt"
fi

ln -sfn "$PRED_DIR" "result/lerf_mask/$SCENE"

python script/eval_lerf_mask.py "$SCENE" \
  2>&1 | tee "$PROJECT_DIR/logs/eval_${OUTPUT_NAME}.log"
