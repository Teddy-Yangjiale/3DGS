# Teatime Result

See [LERF-MASK Results](lerf_mask_results.md) for the cross-scene summary.

Scene:

```text
LERF-MASK / teatime
```

Training setup:

```text
resolution scale: -r 1
iterations: 7000
config: configs/gaussian_grouping/train_12gb.json
GPU: NVIDIA TITAN V, 12GB
```

LERF-MASK evaluation:

```text
Overall Mean IoU: 0.6672
Overall Boundary Mean IoU: 0.6365
```

Mean IoU per class:

```text
spoon handle: 0.0000
sheep: 0.6359
coffee mug: 0.8510
stuffed bear: 0.6426
plate: 0.8712
paper napkin: 0.8271
cookies on a plate: 0.2229
bag of cookies: 0.9479
tea in a glass: 0.7681
apple: 0.9050
```

Mean Boundary IoU per class:

```text
spoon handle: 0.0000
sheep: 0.5996
coffee mug: 0.8510
stuffed bear: 0.5191
plate: 0.8712
paper napkin: 0.8229
cookies on a plate: 0.1144
bag of cookies: 0.9483
tea in a glass: 0.7371
apple: 0.9010
```

Observation:

`teatime` is the weakest scene under the current 12GB baseline. Large or distinctive objects remain strong, but `spoon handle` fails completely and `cookies on a plate` is weak. These are useful failure cases for the enhancement section because they expose limitations on thin objects and semantically entangled object groups.

