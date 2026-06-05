# Reproduction Notes

This project reproduces object-level segmentation in 3D Gaussian Splatting with Gaussian Grouping on LERF-MASK.

## Repository Layout

```text
~/3DGS/
  configs/gaussian_grouping/train_12gb.json
  data/lerf_mask/
  checkpoints/
  logs/
  outputs/
  scripts/
  third_party/gaussian-grouping/
```

Only code, configs, scripts, and documentation are committed. Datasets, checkpoints, logs, trained 3DGS outputs, videos, and large masks stay out of Git.

## Server Environment

Observed server environment:

```text
GPU: NVIDIA TITAN V, 12GB
NVIDIA driver: 580.159.03
System CUDA toolkit: 11.8
Conda env: gaussian_grouping
Python: 3.8
PyTorch: 1.12.1
Conda cudatoolkit: 11.3
```

Key CUDA extension settings used for TITAN V:

```bash
export TORCH_CUDA_ARCH_LIST="7.0"
export MAX_JOBS=2
```

Runtime library path used before training and rendering:

```bash
source scripts/env_gaussian_grouping.sh
```

## Dataset

LERF-MASK scenes are stored under:

```text
data/lerf_mask/
  figurines/
  ramen/
  teatime/
```

Each scene should contain:

```text
images/
images_train/
object_mask/
sparse/
test_mask/
```

Inside the Gaussian Grouping repository, create symlinks:

```bash
cd ~/3DGS/third_party/gaussian-grouping
mkdir -p data
ln -sfn ~/3DGS/data/lerf_mask data/lerf
ln -sfn ~/3DGS/data/lerf_mask data/lerf_mask
```

## Offline Checkpoints

The server cannot access Hugging Face directly, so the following files are downloaded locally and uploaded to the server.

GroundingDINO:

```text
checkpoints/groundingdino/GroundingDINO_SwinB.cfg.py
checkpoints/groundingdino/GroundingDINO_SwinB.local.cfg.py
checkpoints/groundingdino/groundingdino_swinb_cogcoor.pth
```

BERT:

```text
checkpoints/bert-base-uncased/config.json
checkpoints/bert-base-uncased/tokenizer_config.json
checkpoints/bert-base-uncased/tokenizer.json
checkpoints/bert-base-uncased/vocab.txt
checkpoints/bert-base-uncased/pytorch_model.bin
```

These files are not committed to Git.

## Training

For 12GB TITAN V, the successful `figurines` run used:

```bash
conda activate gaussian_grouping
cd ~/3DGS/third_party/gaussian-grouping
source ~/3DGS/scripts/env_gaussian_grouping.sh

CUDA_VISIBLE_DEVICES=0 python train.py \
  -s data/lerf/figurines \
  -r 1 \
  -m output/lerf/figurines \
  --config_file ~/3DGS/configs/gaussian_grouping/train_12gb.json \
  --train_split \
  --iterations 7000 \
  --test_iterations 1000 7000 \
  --save_iterations 1000 7000
```

The `-r 2` setting was not used in the completed run because RGB images were resized but `object_mask` targets stayed at the original size in the current code path.

## Rendering And Evaluation

Generate text-prompt masks:

```bash
CUDA_VISIBLE_DEVICES=0 python render_lerf_mask.py \
  -m output/lerf/figurines \
  --skip_train
```

The script writes masks to:

```text
output/lerf/figurines/test/ours_7000_text/test_mask/
```

The evaluation script expects:

```text
result/lerf_mask/figurines/
```

Create a symlink:

```bash
mkdir -p result/lerf_mask
ln -sfn "$(pwd)/output/lerf/figurines/test/ours_7000_text/test_mask" result/lerf_mask/figurines
```

Evaluate:

```bash
python script/eval_lerf_mask.py figurines
```

