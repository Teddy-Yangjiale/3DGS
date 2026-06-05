# 3DGS Object Segmentation Project

This repository tracks code, scripts, notes, and report material for object-level segmentation and editing in 3D Gaussian Splatting.

Large datasets, trained models, rendered videos, and checkpoints are intentionally excluded from Git. Put them on the lab server under `/data1` or `/data2`.

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

Follow the upstream install notes if package versions need adjustment:

- https://github.com/lkeab/gaussian-grouping
- https://github.com/lkeab/gaussian-grouping/blob/main/docs/install.md

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

