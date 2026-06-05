# Experiment Protocol

This document defines how we name and store experiments so repeated LERF-MASK runs do not overwrite each other.

## Goals

The repository should separate:

```text
baseline reproduction
parameter tuning
prompt/mask tuning
downstream editing
custom data validation
```

Only scripts, configs, docs, and selected report assets are committed to Git. Raw datasets, outputs, checkpoints, logs, and third-party source trees stay on the server.

## Naming

Use this format:

```text
<scene>_<experiment>
```

Examples:

```text
figurines_baseline_12gb_7000
ramen_baseline_12gb_7000
teatime_baseline_12gb_7000
teatime_densify1500_7000
teatime_prompt_spoon_7000
```

The current legacy baseline output directories are:

```text
output/lerf/figurines
output/lerf/ramen
output/lerf/teatime
```

The first enhancement was also run with a legacy short name:

```text
output/lerf/teatime_densify1500
```

New experiments should use explicit names such as:

```text
output/lerf/teatime_densify1500_7000
```

This avoids replacing baseline models.

## Server Layout

Recommended server-only layout:

```text
~/3DGS/
  data/
    lerf_mask/
  checkpoints/
    groundingdino/
    bert-base-uncased/
  logs/
  outputs/
  third_party/
    gaussian-grouping/
      output/lerf/
      result/lerf_mask/
      result/lerf_mask_trials/
```

Committed layout:

```text
configs/
  gaussian_grouping/
docs/
scripts/
README.md
PROJECT_PLAN.md
```

## Running A Named Experiment

For a named parameter experiment:

```bash
cd ~/3DGS
bash scripts/train_lerf_experiment.sh \
  teatime \
  densify1500_7000 \
  configs/gaussian_grouping/train_12gb_densify1500.json \
  0 \
  7000

bash scripts/render_eval_lerf_experiment.sh teatime densify1500_7000 0 7000
```

This writes:

```text
third_party/gaussian-grouping/output/lerf/teatime_densify1500_7000/
logs/train_teatime_densify1500_7000.log
logs/render_lerf_mask_teatime_densify1500_7000.log
logs/eval_teatime_densify1500_7000.log
```

It also creates:

```text
third_party/gaussian-grouping/result/lerf_mask_trials/teatime_densify1500_7000
```

For compatibility with the upstream evaluator, it temporarily points:

```text
third_party/gaussian-grouping/result/lerf_mask/teatime
```

to the current experiment predictions. To restore the legacy baseline link:

```bash
cd ~/3DGS/third_party/gaussian-grouping
ln -sfn "$(pwd)/output/lerf/teatime/test/ours_7000_text/test_mask" result/lerf_mask/teatime
```

## Recording Results

Every experiment should record:

```text
scene
experiment name
config path
iterations
GPU
Mean IoU
Boundary Mean IoU
weak classes
whether OOM occurred
notes on qualitative masks
```

Add completed results to:

```text
docs/lerf_mask_results.md
```

Use scene-specific result pages only when a scene needs detailed discussion.
