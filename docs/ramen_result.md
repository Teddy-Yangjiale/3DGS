# Ramen Result

See [LERF-MASK Results](lerf_mask_results.md) for the cross-scene summary.

Scene:

```text
LERF-MASK / ramen
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
Overall Mean IoU: 0.7620
Overall Boundary Mean IoU: 0.6805
```

Mean IoU per class:

```text
chopsticks: 0.8278
egg: 0.9131
yellow bowl: 0.9030
glass of water: 0.8921
pork belly: 0.9414
wavy noodles in bowl: 0.0945
```

Mean Boundary IoU per class:

```text
chopsticks: 0.8278
egg: 0.8097
yellow bowl: 0.8140
glass of water: 0.7949
pork belly: 0.8233
wavy noodles in bowl: 0.0132
```

Observation:

The overall Mean IoU is close to `figurines`, but Boundary Mean IoU is lower. The dominant failure is `wavy noodles in bowl`, which is visually and semantically entangled with the bowl and other food items.

