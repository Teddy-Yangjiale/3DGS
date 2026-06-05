# 3DGS Object Segmentation Project

This repository tracks a reproducible setup for object-level segmentation and editing in 3D Gaussian Splatting. The current reproduced method is Gaussian Grouping on LERF-MASK.

Large datasets, trained models, rendered videos, logs, third-party source trees, and checkpoints are intentionally excluded from Git. Put them on the lab server under `/data1` or `/data2`.

## Recommended Layout

Local workspace:

```text
/home/teddy/3DGS/
  third_party/gaussian-grouping/
  data/
  outputs/
  checkpoints/
  logs/
  scripts/
  report/
```

Server workspace:

```text
/data2/$USER/3DGS/
  third_party/gaussian-grouping/
  data/
  outputs/
  checkpoints/
  logs/
  scripts/
  report/
```

## Server Rules

- Connect with `ssh <account>@172.18.35.215`.
- Store code, datasets, models, and outputs only under `/data1` or `/data2`.
- The server default CUDA Toolkit is 11.8.
- Always specify a GPU when running training or rendering:

```bash
CUDA_VISIBLE_DEVICES=0 python train.py ...
```

## First Setup

On the server:

```bash
mkdir -p /data2/$USER/3DGS
cd /data2/$USER/3DGS
git clone https://github.com/Teddy-Yangjiale/3DGS .
bash scripts/server_setup.sh
```

Then clone the reproduction method:

```bash
mkdir -p third_party
git clone --recursive https://github.com/lkeab/gaussian-grouping third_party/gaussian-grouping
```

Follow the full project reproduction guide:

- [docs/reproduction.md](docs/reproduction.md)
- [docs/parameters.md](docs/parameters.md)
- [docs/lerf_mask_results.md](docs/lerf_mask_results.md)
- [docs/bottleneck_analysis.md](docs/bottleneck_analysis.md)
- [docs/figurines_result.md](docs/figurines_result.md)

## Dataset Placement

Use this structure on both local and server machines:

```text
data/
  lerf_mask/
    figurines/
    ramen/
    teatime/
  mipnerf360/
  custom/
    desk_objects/
```

On the server, the real path should be:

```text
/data2/$USER/3DGS/data/
```

Do not put datasets in `/home`, `/tmp`, or system directories.

## Current Reproduced Results

Completed scenes:

```text
LERF-MASK / figurines
LERF-MASK / ramen
LERF-MASK / teatime
```

Baseline setting:

```text
resolution scale: -r 1
iterations: 7000
config: configs/gaussian_grouping/train_12gb.json
GPU: NVIDIA TITAN V, 12GB
```

Results:

```text
figurines  Mean IoU: 0.7630  Boundary IoU: 0.7427
ramen      Mean IoU: 0.7620  Boundary IoU: 0.6805
teatime    Mean IoU: 0.6672  Boundary IoU: 0.6365
```

Working commands after environment and data setup:

```bash
bash scripts/train_lerf_12gb.sh figurines 0 7000
bash scripts/render_eval_lerf.sh figurines 0 7000
bash scripts/train_lerf_12gb.sh ramen 0 7000
bash scripts/render_eval_lerf.sh ramen 0 7000
bash scripts/train_lerf_12gb.sh teatime 0 7000
bash scripts/render_eval_lerf.sh teatime 0 7000
```
