# Figurines Result

See [LERF-MASK Results](lerf_mask_results.md) for the cross-scene summary.

Scene:

```text
LERF-MASK / figurines
```

Training setup:

```text
resolution scale: -r 1
iterations: 7000
config: configs/gaussian_grouping/train_12gb.json
GPU: NVIDIA TITAN V, 12GB
```

Training reconstruction metrics:

```text
ITER 1000:
  L1   = 0.0927
  PSNR = 17.99

ITER 7000:
  L1   = 0.0581
  PSNR = 22.13
```

LERF-MASK evaluation:

```text
Overall Mean IoU: 0.7630
Overall Boundary Mean IoU: 0.7427
```

Mean IoU per class:

```text
rubber duck with red hat: 0.2512
red apple: 0.9486
porcelain hand: 0.8611
green toy chair: 0.8646
old camera: 0.5955
red toy chair: 0.8979
green apple: 0.9222
```

Mean Boundary IoU per class:

```text
rubber duck with red hat: 0.2631
red apple: 0.9063
porcelain hand: 0.8571
green toy chair: 0.8363
old camera: 0.5715
red toy chair: 0.8776
green apple: 0.8866
```

Observation:

Most medium-sized objects are segmented well. The weakest category is `rubber duck with red hat`, likely because the object is small, visually ambiguous, or less stable under text-prompt localization and low-memory Gaussian densification.
