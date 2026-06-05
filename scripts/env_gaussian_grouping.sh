#!/usr/bin/env bash
set -euo pipefail

if [ -z "${CONDA_PREFIX:-}" ]; then
  echo "Activate the gaussian_grouping conda environment first."
  return 1 2>/dev/null || exit 1
fi

ln -sfn /usr/lib/x86_64-linux-gnu/libcuda.so.1 "$CONDA_PREFIX/lib/libcuda.so" 2>/dev/null || true

export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:/usr/local/cuda-11.8/lib64:/usr/local/cuda-11.8/targets/x86_64-linux/lib:${LD_LIBRARY_PATH:-}"
export PYTORCH_CUDA_ALLOC_CONF="${PYTORCH_CUDA_ALLOC_CONF:-max_split_size_mb:128}"
export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-7.0}"
export MAX_JOBS="${MAX_JOBS:-2}"

