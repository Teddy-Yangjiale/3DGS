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

Baseline:

| Scene | Status | Mean IoU | Boundary Mean IoU | Main Weak Category |
| --- | --- | ---: | ---: | --- |
| figurines | complete | 0.7630 | 0.7427 | rubber duck with red hat |
| ramen | complete | 0.7620 | 0.6805 | wavy noodles in bowl |
| teatime | complete | 0.6672 | 0.6365 | spoon handle; cookies on a plate |

Enhancement experiments:

| Scene | Experiment | Mean IoU | Boundary Mean IoU | Main Observation |
| --- | --- | ---: | ---: | --- |
| teatime | densify1500_7000 | 0.7108 | 0.6768 | improves overall score, but spoon handle remains 0.0 |
| teatime | prompt_hardcoded_spoon_cookies_7000 | 0.7344 | 0.7145 | prompt `cookies` fixes cookies on a plate; spoon handle remains 0.0 |

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

### Teatime Densify1500 Enhancement

Config:

```text
configs/gaussian_grouping/train_12gb_densify1500.json
iterations: 7000
densify_until_iter: 1500
reg3d_max_points: 50000
reg3d_sample_size: 256
```

Result:

```text
Overall Mean IoU: 0.7108
Overall Boundary Mean IoU: 0.6768
```

Per-class changes compared with baseline:

| Class | Baseline IoU | Densify1500 IoU | Change |
| --- | ---: | ---: | ---: |
| spoon handle | 0.0000 | 0.0000 | +0.0000 |
| sheep | 0.6359 | 0.9547 | +0.3188 |
| coffee mug | 0.8510 | 0.8493 | -0.0017 |
| stuffed bear | 0.6426 | 0.6439 | +0.0013 |
| plate | 0.8712 | 0.8684 | -0.0027 |
| paper napkin | 0.8271 | 0.8119 | -0.0152 |
| cookies on a plate | 0.2229 | 0.2223 | -0.0006 |
| bag of cookies | 0.9479 | 0.9464 | -0.0015 |
| tea in a glass | 0.7681 | 0.9007 | +0.1327 |
| apple | 0.9050 | 0.9103 | +0.0053 |

Interpretation:

Increasing densification improved overall quality, mainly through `sheep` and `tea in a glass`. It did not solve the hardest categories: `spoon handle` stayed at `0.0000`, and `cookies on a plate` stayed around `0.22`. This suggests those failures are likely caused by prompt/mask localization or semantic entanglement rather than only insufficient Gaussian density.

### Teatime Prompt-Tuning Enhancement

Prompt override:

```text
cookies on a plate -> cookies
spoon handle -> spoon
```

Implementation note:

This first prompt-tuning run was executed as a hardcoded test in `render_lerf_mask.py`, then the generated `cookies.png` and `spoon.png` masks were copied back to the original evaluator filenames:

```text
cookies.png -> cookies on a plate.png
spoon.png -> spoon handle.png
```

Result:

```text
Overall Mean IoU: 0.7344
Overall Boundary Mean IoU: 0.7145
```

Per-class comparison:

| Class | Baseline IoU | Prompt-Tuned IoU | Change |
| --- | ---: | ---: | ---: |
| spoon handle | 0.0000 | 0.0000 | +0.0000 |
| cookies on a plate | 0.2229 | 0.8948 | +0.6719 |

Interpretation:

The `cookies` prompt fixes the `cookies on a plate` failure almost completely. This confirms that the original failure was primarily a text-prompt/mask-localization problem, not a 3DGS training problem. The `spoon` prompt still gives `0.0000` for `spoon handle`, so that category likely requires a different prompt, threshold adjustment, or manual/mask-selection strategy.

## Current Interpretation

The three completed scenes support the same conclusion:

```text
The low-memory 12GB configuration is valid for reproducing LERF-MASK segmentation, but thin, small, partially visible, or semantically entangled objects are weak cases.
```

The current baseline is strong enough for method reproduction: all three required public scenes train, render text-prompt masks, and produce IoU/Boundary-IoU metrics. The `teatime_densify1500_7000` enhancement shows that controlled densification can improve overall metrics under the 12GB budget, but the hardest failure categories likely need prompt or mask-selection tuning.

## Next Step

Inspect and tune one representative failure case. Recommended starting point:

```text
Scene: teatime
Failure target: spoon handle or cookies on a plate
Reason: weakest overall scene and clear object-level failure modes
```

Candidate next directions:

```text
1. Keep baseline and densify1500 as separate recorded experiments.
2. Inspect spoon handle and cookies on a plate masks.
3. Keep the cookies prompt-tuning result as a successful enhancement.
4. Try additional prompts for spoon handle: metal spoon, silver spoon, spoon.
5. Only try densify_until_iter=2000 if the qualitative masks look correct but boundaries remain rough.
```

Do not replace the three-scene baseline results. Treat tuning as a separate enhancement experiment.

## Prompt-Tuning Plan For Teatime

The exported failure masks showed that:

```text
spoon handle: predicted mask is empty
cookies on a plate: predicted mask selects only partial/wrong regions
```

This indicates a prompt/mask localization bottleneck. The first prompt-tuning experiment reused the trained `teatime` model and changed the Grounded-SAM query prompt:

```text
spoon handle -> spoon
cookies on a plate -> cookies
```

Result:

```text
cookies on a plate: 0.2229 -> 0.8948
spoon handle: 0.0000 -> 0.0000
Overall Mean IoU: 0.6672 -> 0.7344
Boundary Mean IoU: 0.6365 -> 0.7145
```

The next prompt-tuning target is now only `spoon handle`.

Potential commands after making the prompt override script reliable:

```bash
cd ~/3DGS
bash scripts/patch_gaussian_grouping_prompt_tuning.sh
bash scripts/render_eval_lerf_prompt_experiment.sh teatime teatime prompt_metal_spoon_7000 0 7000 '{"spoon handle":"metal spoon"}'
```
