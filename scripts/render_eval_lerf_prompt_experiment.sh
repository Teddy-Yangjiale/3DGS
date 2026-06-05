#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 6 ]; then
  echo "Usage: bash scripts/render_eval_lerf_prompt_experiment.sh <scene> <model_name> <experiment> <gpu_id> <iteration> <prompt_overrides_json>"
  echo "Example: bash scripts/render_eval_lerf_prompt_experiment.sh teatime teatime prompt_spoon_7000 0 7000 '{\"spoon handle\":\"spoon\"}'"
  exit 1
fi

SCENE="$1"
MODEL_NAME="$2"
EXPERIMENT="$3"
GPU_ID="$4"
ITERATION="$5"
PROMPT_OVERRIDES="$6"

PROJECT_DIR="${PROJECT_DIR:-$HOME/3DGS}"
GG_DIR="${GG_DIR:-$PROJECT_DIR/third_party/gaussian-grouping}"
OUTPUT_TAG="ours_${ITERATION}_${EXPERIMENT}"

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
mkdir -p "$PROJECT_DIR/logs" result/lerf_mask result/lerf_mask_trials

CUDA_VISIBLE_DEVICES="$GPU_ID" python render_lerf_mask.py \
  -m "output/lerf/$MODEL_NAME" \
  --skip_train \
  --output_tag "$OUTPUT_TAG" \
  --prompt_overrides "$PROMPT_OVERRIDES" \
  2>&1 | tee "$PROJECT_DIR/logs/render_lerf_mask_${SCENE}_${EXPERIMENT}.log"

PRED_DIR="$(pwd)/output/lerf/$MODEL_NAME/test/$OUTPUT_TAG/test_mask"
ln -sfn "$PRED_DIR" "result/lerf_mask_trials/${SCENE}_${EXPERIMENT}"

if [ -L "result/lerf_mask/$SCENE" ]; then
  readlink "result/lerf_mask/$SCENE" > "result/lerf_mask_trials/${SCENE}_previous_link.txt"
fi

ln -sfn "$PRED_DIR" "result/lerf_mask/$SCENE"

python script/eval_lerf_mask.py "$SCENE" \
  2>&1 | tee "$PROJECT_DIR/logs/eval_${SCENE}_${EXPERIMENT}.log"
