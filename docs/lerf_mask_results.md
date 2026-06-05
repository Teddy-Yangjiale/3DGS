# LERF-MASK Results

This page records the current public-scene baseline for Gaussian Grouping on LERF-MASK.

## Baseline Setup

Hardware and environment:

```text
GPU: NVIDIA TITAN V, 12GB
Conda env: gaussian_grouping
Method: Gaussian Grouping
Dataset: LERF-MASK
```

Training setup:

```text
resolution scale: -r 1
iterations: 7000
config: configs/gaussian_grouping/train_12gb.json
```

The `-r 1` setting is required for the current code path because `-r 2` downsamples RGB images but does not downsample `object_mask`, causing image/mask size mismatch.

## Overall Metrics

| Scene | Status | Mean IoU | Boundary Mean IoU | Main Weak Category |
| --- | --- | ---: | ---: | --- |
| figurines | complete | 0.7630 | 0.7427 | rubber duck with red hat |
| ramen | complete | 0.7620 | 0.6805 | wavy noodles in bowl |
| teatime | pending | - | - | - |

## Figurines

Mean IoU per class:

| Class | Mean IoU | Boundary IoU |
| --- | ---: | ---: |
| rubber duck with red hat | 0.2512 | 0.2631 |
| red apple | 0.9486 | 0.9063 |
| porcelain hand | 0.8611 | 0.8571 |
| green toy chair | 0.8646 | 0.8363 |
| old camera | 0.5955 | 0.5715 |
| red toy chair | 0.8979 | 0.8776 |
| green apple | 0.9222 | 0.8866 |

Observation:

Most medium-sized, visually distinctive objects are segmented well. The weakest category is `rubber duck with red hat`, which should be treated as a failure case for qualitative inspection.

## Ramen

Mean IoU per class:

| Class | Mean IoU | Boundary IoU |
| --- | ---: | ---: |
| chopsticks | 0.8278 | 0.8278 |
| egg | 0.9131 | 0.8097 |
| yellow bowl | 0.9030 | 0.8140 |
| glass of water | 0.8921 | 0.7949 |
| pork belly | 0.9414 | 0.8233 |
| wavy noodles in bowl | 0.0945 | 0.0132 |

Observation:

The scene-level Mean IoU is almost the same as `figurines`, but the Boundary Mean IoU is lower. The main reason is `wavy noodles in bowl`, which is nearly a complete failure. This category is visually entangled with the bowl and other food items, so text-prompt localization and 3D grouping likely struggle to isolate it cleanly.

One command output showed `find result/lerf_mask/ramen -type f | wc -l` as `0`, while evaluation still loaded masks and produced valid IoU. This means the path/symlink check should be repeated carefully before final archiving, but the evaluation itself did find readable prediction files through `result/lerf_mask/ramen`.

## Current Interpretation

The two completed scenes support the same conclusion:

```text
The low-memory 12GB configuration is valid for reproducing LERF-MASK segmentation, but thin, small, or semantically entangled objects are weak cases.
```

We should not tune parameters yet. The next step is to run `teatime` with the same baseline setting so that all three required scenes are comparable. After that, tune one representative failure case instead of overfitting to a single scene.

## Next Step

Run `teatime` with the same baseline:

```bash
cd ~/3DGS
bash scripts/train_lerf_12gb.sh teatime 0 7000
bash scripts/render_eval_lerf.sh teatime 0 7000
```

