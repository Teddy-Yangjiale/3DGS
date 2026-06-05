# Reproduction Guide

This guide records the working reproduction path for Gaussian Grouping on LERF-MASK with a 12GB NVIDIA TITAN V server. It is written for the lab server where outbound access to Hugging Face may be unavailable.

## 0. What This Repository Contains

Committed to GitHub:

```text
configs/                 Low-memory training config
docs/                    Reproduction notes and result summaries
scripts/                 Environment, patch, training, rendering, evaluation helpers
README.md
PROJECT_PLAN.md
```

Not committed:

```text
data/lerf_mask/          LERF-MASK dataset
third_party/             Gaussian Grouping source tree
checkpoints/             GroundingDINO, BERT, SAM, trained weights
outputs/ and output/     Rendered results and model outputs
logs/                    Runtime logs
```

## 1. Expected Workspace

Use `/data1` or `/data2` on the server. The lab server guideline says not to store large files on the system disk.

```bash
mkdir -p /data2/$USER/3DGS
cd /data2/$USER/3DGS
git clone https://github.com/Teddy-Yangjiale/3DGS .
```

The final workspace should look like:

```text
~/3DGS/
  configs/gaussian_grouping/train_12gb.json
  data/lerf_mask/
  checkpoints/
  logs/
  scripts/
  third_party/gaussian-grouping/
```

## 2. Clone Gaussian Grouping

```bash
cd ~/3DGS
mkdir -p third_party
git clone --recursive https://github.com/lkeab/gaussian-grouping third_party/gaussian-grouping
```

If the submodules are incomplete:

```bash
cd ~/3DGS/third_party/gaussian-grouping
git submodule update --init --recursive
```

## 3. Prepare LERF-MASK

Because the server may not download files directly, download the three zip files locally and upload them by `scp`.

Expected server layout:

```text
~/3DGS/data/lerf_mask/
  figurines/
  ramen/
  teatime/
```

Each scene should contain at least:

```text
images/
images_train/
object_mask/
sparse/
test_mask/
```

Create symlinks for the upstream code:

```bash
cd ~/3DGS/third_party/gaussian-grouping
mkdir -p data
ln -sfn ~/3DGS/data/lerf_mask data/lerf
ln -sfn ~/3DGS/data/lerf_mask data/lerf_mask
```

Check:

```bash
find data/lerf_mask -maxdepth 2 -type d | sort | head -50
```

## 4. Create Conda Environment

```bash
cd ~/3DGS/third_party/gaussian-grouping

conda create -n gaussian_grouping python=3.8 -y
conda activate gaussian_grouping

conda install pytorch==1.12.1 torchvision==0.13.1 torchaudio==0.12.1 cudatoolkit=11.3 -c pytorch -y

pip install plyfile==0.8.1
pip install tqdm scipy wandb opencv-python scikit-learn lpips ninja
```

## 5. Compile 3DGS CUDA Extensions

The TITAN V uses compute capability 7.0. The server's default compiler may be too new for CUDA 11.8, so install a compatible conda compiler.

```bash
conda activate gaussian_grouping
cd ~/3DGS/third_party/gaussian-grouping

conda install -c conda-forge gcc_linux-64=11 gxx_linux-64=11 libxcrypt sysroot_linux-64 -y

export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

export CC=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gcc
export CXX=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-g++
export CUDAHOSTCXX=$CXX
export CPATH=$CONDA_PREFIX/include:$CPATH
export TORCH_CUDA_ARCH_LIST="7.0"
export MAX_JOBS=2

python -m pip install --no-build-isolation --no-cache-dir submodules/diff-gaussian-rasterization
python -m pip install --no-build-isolation --no-cache-dir submodules/simple-knn
```

Check:

```bash
python - <<'PY'
import torch
import diff_gaussian_rasterization
import simple_knn
print("extensions OK")
print("torch:", torch.__version__)
print("cuda available:", torch.cuda.is_available())
print("gpu:", torch.cuda.get_device_name(0) if torch.cuda.is_available() else "none")
PY
```

## 6. Runtime Environment Variables

Before each training or rendering run:

```bash
conda activate gaussian_grouping
source ~/3DGS/scripts/env_gaussian_grouping.sh
```

This script sets:

```text
LD_LIBRARY_PATH
PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128
TORCH_CUDA_ARCH_LIST=7.0
MAX_JOBS=2
```

It also links `libcuda.so` into the conda environment when possible. This avoids runtime failures such as:

```text
libcuda.so: cannot open shared object file
```

## 7. Install Grounded-SAM Dependencies

`render_lerf_mask.py` needs GroundingDINO and Segment Anything.

```bash
conda activate gaussian_grouping
cd ~/3DGS/third_party/gaussian-grouping

git submodule update --init --recursive

cd Tracking-Anything-with-DEVA
python -m pip install -e .

git clone https://github.com/hkchengrex/Grounded-Segment-Anything.git
cd Grounded-Segment-Anything

export AM_I_DOCKER=False
export BUILD_WITH_CUDA=True

python -m pip install -e segment_anything
python -m pip install -e GroundingDINO
```

Check:

```bash
python - <<'PY'
import groundingdino
import segment_anything
print("GroundingDINO and SAM import OK")
PY
```

## 8. Offline Checkpoints

The server may not access Hugging Face. Download these files locally and upload them to the server.

GroundingDINO:

```text
https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/GroundingDINO_SwinB.cfg.py
https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/groundingdino_swinb_cogcoor.pth
```

BERT:

```text
https://huggingface.co/bert-base-uncased/resolve/main/config.json
https://huggingface.co/bert-base-uncased/resolve/main/tokenizer_config.json
https://huggingface.co/bert-base-uncased/resolve/main/tokenizer.json
https://huggingface.co/bert-base-uncased/resolve/main/vocab.txt
https://huggingface.co/bert-base-uncased/resolve/main/pytorch_model.bin
```

Server layout:

```text
~/3DGS/checkpoints/groundingdino/
  GroundingDINO_SwinB.cfg.py
  groundingdino_swinb_cogcoor.pth

~/3DGS/checkpoints/bert-base-uncased/
  config.json
  tokenizer_config.json
  tokenizer.json
  vocab.txt
  pytorch_model.bin
```

If using Windows PowerShell:

```powershell
scp "D:\Downloads\GroundingDINO_SwinB.cfg.py" "D:\Downloads\groundingdino_swinb_cogcoor.pth" cse12411723@172.18.35.215:~/3DGS/checkpoints/groundingdino/

scp "D:\Downloads\bert-base-uncased\config.json" "D:\Downloads\bert-base-uncased\tokenizer_config.json" "D:\Downloads\bert-base-uncased\tokenizer.json" "D:\Downloads\bert-base-uncased\vocab.txt" "D:\Downloads\bert-base-uncased\pytorch_model.bin" cse12411723@172.18.35.215:~/3DGS/checkpoints/bert-base-uncased/
```

## 9. Patch Gaussian Grouping For Offline Rendering

Apply the local patch script after cloning Gaussian Grouping and uploading the offline checkpoints:

```bash
cd ~/3DGS
bash scripts/patch_gaussian_grouping_offline.sh
```

This patch does four things:

```text
1. Makes ext/grounded_sam.py load local GroundingDINO config and weights.
2. Makes render_lerf_mask.py use the local GroundingDINO config.
3. Makes GroundingDINO accept a local BERT directory.
4. Skips a visualization-only supervision annotate call with an incompatible API.
```

Check local BERT:

```bash
cd ~/3DGS/third_party/gaussian-grouping/Tracking-Anything-with-DEVA/Grounded-Segment-Anything/GroundingDINO
python - <<'PY'
from groundingdino.util.get_tokenlizer import get_tokenlizer, get_pretrained_language_model
import os
bert_path = os.path.expanduser("~/3DGS/checkpoints/bert-base-uncased")
tok = get_tokenlizer(bert_path)
model = get_pretrained_language_model(bert_path)
print("local BERT OK")
PY
```

## 10. Train Figurines

The working low-memory run used `-r 1`. We did not use `-r 2` because the RGB images were resized but `object_mask` targets stayed at the original resolution in this code path.

```bash
cd ~/3DGS
bash scripts/train_lerf_12gb.sh figurines 0 7000
```

Equivalent explicit command:

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

The successful run produced:

```text
ITER 1000:
  L1   = 0.0927
  PSNR = 17.99

ITER 7000:
  L1   = 0.0581
  PSNR = 22.13
```

## 11. Render Text-Prompt Masks And Evaluate

```bash
cd ~/3DGS
bash scripts/render_eval_lerf.sh figurines 0 7000
```

Equivalent explicit commands:

```bash
conda activate gaussian_grouping
cd ~/3DGS/third_party/gaussian-grouping
source ~/3DGS/scripts/env_gaussian_grouping.sh

CUDA_VISIBLE_DEVICES=0 python render_lerf_mask.py \
  -m output/lerf/figurines \
  --skip_train

mkdir -p result/lerf_mask
ln -sfn "$(pwd)/output/lerf/figurines/test/ours_7000_text/test_mask" result/lerf_mask/figurines

python script/eval_lerf_mask.py figurines
```

The successful `figurines` evaluation produced:

```text
Overall Mean IoU: 0.7630
Overall Boundary Mean IoU: 0.7427
```

## 12. Known Issues And Fixes

`ModuleNotFoundError: diff_gaussian_rasterization` or `simple_knn`:

```text
The CUDA extensions were not compiled in the active conda environment.
Compile them after activating gaussian_grouping.
```

`Unknown CUDA arch (8.9)`:

```text
PyTorch 1.12 does not recognize a newer default arch. Set TORCH_CUDA_ARCH_LIST=7.0 for TITAN V.
```

`unsupported GNU version`:

```text
System gcc is too new for CUDA 11.8. Use conda gcc/g++ 11.
```

`crypt.h: No such file or directory`:

```text
Install libxcrypt/sysroot_linux-64 in conda and expose CONDA_PREFIX/include.
```

`libcuda.so: cannot open shared object file`:

```text
Run source ~/3DGS/scripts/env_gaussian_grouping.sh before training/rendering.
```

`input and target batch or spatial sizes don't match` with `-r 2`:

```text
RGB images were downsampled but object_mask stayed at original size. Use -r 1 unless the mask loader or masks are resized consistently.
```

`huggingface.co ... Network is unreachable`:

```text
Upload GroundingDINO and BERT files manually, then run scripts/patch_gaussian_grouping_offline.sh.
```

`annotate() got an unexpected keyword argument 'labels'`:

```text
supervision API version mismatch. The offline patch skips visualization annotation and keeps mask generation.
```
