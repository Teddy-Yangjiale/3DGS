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
| teatime | complete | 0.6672 | 0.6365 | spoon handle; cookies on a plate |

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

## Teatime

Mean IoU per class:

| Class | Mean IoU | Boundary IoU |
| --- | ---: | ---: |
| spoon handle | 0.0000 | 0.0000 |
| sheep | 0.6359 | 0.5996 |
| coffee mug | 0.8510 | 0.8510 |
| stuffed bear | 0.6426 | 0.5191 |
| plate | 0.8712 | 0.8712 |
| paper napkin | 0.8271 | 0.8229 |
| cookies on a plate | 0.2229 | 0.1144 |
| bag of cookies | 0.9479 | 0.9483 |
| tea in a glass | 0.7681 | 0.7371 |
| apple | 0.9050 | 0.9010 |

Observation:

`teatime` is the weakest completed scene. Several large or distinctive objects are still segmented well, including `bag of cookies`, `apple`, `plate`, `coffee mug`, and `paper napkin`. The failures are concentrated on thin, partially visible, or composition-like targets. `spoon handle` fails completely, and `cookies on a plate` is weak because the prompt describes a sub-object group that is visually entangled with the plate.

One command output showed `find result/lerf_mask/teatime -type f | wc -l` as `0`, while evaluation still loaded masks and produced valid IoU. As with `ramen`, repeat path checks before final packaging, but the metric output confirms that evaluation read prediction masks.

## Current Interpretation

The three completed scenes support the same conclusion:

```text
The low-memory 12GB configuration is valid for reproducing LERF-MASK segmentation, but thin, small, partially visible, or semantically entangled objects are weak cases.
```

The current baseline is strong enough for method reproduction: all three required public scenes train, render text-prompt masks, and produce IoU/Boundary-IoU metrics. The next step is parameter tuning on a representative failure case instead of changing the baseline for every scene.

## Next Step

Tune one representative failure case. Recommended starting point:

```text
Scene: teatime
Failure target: spoon handle or cookies on a plate
Reason: weakest overall scene and clear object-level failure modes
```

Candidate tuning directions:

```text
1. Increase densify_until_iter from 1000 to 1500 if memory permits.
2. Keep iterations at 7000 first, then try 10000 only if memory remains stable.
3. Reduce reg3d_sample_size or reg3d_max_points if more densification causes OOM.
4. Inspect rendered prompt masks before tuning to separate GroundingDINO/SAM failures from 3D grouping failures.
```

Do not replace the three-scene baseline results. Treat tuning as a separate enhancement experiment.
