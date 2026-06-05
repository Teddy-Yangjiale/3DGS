#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 5 ]; then
  echo "Usage: bash scripts/train_lerf_experiment.sh <scene> <experiment> <config_path> <gpu_id> <iterations>"
  echo "Example: bash scripts/train_lerf_experiment.sh teatime densify1500_7000 configs/gaussian_grouping/train_12gb_densify1500.json 0 7000"
  exit 1
fi

SCENE="$1"
EXPERIMENT="$2"
CONFIG_PATH="$3"
GPU_ID="$4"
ITERATIONS="$5"

PROJECT_DIR="${PROJECT_DIR:-$HOME/3DGS}"
GG_DIR="${GG_DIR:-$PROJECT_DIR/third_party/gaussian-grouping}"
OUTPUT_NAME="${SCENE}_${EXPERIMENT}"

if [[ "$CONFIG_PATH" != /* ]]; then
  CONFIG_PATH="$PROJECT_DIR/$CONFIG_PATH"
fi

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
  -m "output/lerf/$OUTPUT_NAME" \
  --config_file "$CONFIG_PATH" \
  --train_split \
  --iterations "$ITERATIONS" \
  --test_iterations 1000 "$ITERATIONS" \
  --save_iterations 1000 "$ITERATIONS" \
  2>&1 | tee "$PROJECT_DIR/logs/train_${OUTPUT_NAME}.log"
