#!/usr/bin/env bash
set -euo pipefail

mkdir -p data outputs checkpoints logs third_party report

if ! command -v conda >/dev/null 2>&1; then
  echo "conda was not found. Load or install conda on the server first."
  exit 1
fi

echo "Create the project environment manually according to the selected CUDA/PyTorch versions."
echo "Server default CUDA Toolkit: 11.8"
echo
echo "Suggested next commands:"
echo "  conda create -n gaussian_grouping python=3.8 -y"
echo "  conda activate gaussian_grouping"
echo "  # Install PyTorch/CUDA versions compatible with the server driver."
echo "  # Then install Gaussian Grouping requirements from third_party/gaussian-grouping."

