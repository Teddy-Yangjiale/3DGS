# Next Steps

This plan starts from the current completed baseline and one enhancement run.

## Completed

Baseline reproduction:

| Scene | Experiment | Mean IoU | Boundary Mean IoU |
| --- | --- | ---: | ---: |
| figurines | baseline_12gb_7000 | 0.7630 | 0.7427 |
| ramen | baseline_12gb_7000 | 0.7620 | 0.6805 |
| teatime | baseline_12gb_7000 | 0.6672 | 0.6365 |

Enhancement:

| Scene | Experiment | Mean IoU | Boundary Mean IoU |
| --- | --- | ---: | ---: |
| teatime | densify1500_7000 | 0.7108 | 0.6768 |
| teatime | prompt_hardcoded_spoon_cookies_7000 | 0.7344 | 0.7145 |

Note: the first enhancement was run on the server under the legacy path:

```text
output/lerf/teatime_densify1500/
```

Future runs should use explicit names:

```text
output/lerf/teatime_densify1500_7000/
```

## Phase 1: Solidify Results

Goal:

```text
Make all current results easy to trace and reproduce.
```

Actions:

```text
1. Keep the three baseline outputs unchanged.
2. Keep teatime_densify1500 as an enhancement output.
3. Use docs/experiment_protocol.md for new experiment names.
4. Do not overwrite result/lerf_mask/<scene> without recording which experiment it points to.
```

Recommended default symlink state:

```bash
cd ~/3DGS/third_party/gaussian-grouping
ln -sfn "$(pwd)/output/lerf/figurines/test/ours_7000_text/test_mask" result/lerf_mask/figurines
ln -sfn "$(pwd)/output/lerf/ramen/test/ours_7000_text/test_mask" result/lerf_mask/ramen
ln -sfn "$(pwd)/output/lerf/teatime/test/ours_7000_text/test_mask" result/lerf_mask/teatime
```

## Phase 2: Failure Visualization

Goal:

```text
Determine whether weak categories fail because of 3D grouping or because prompt-level GroundingDINO/SAM masks are already wrong.
```

Targets:

```text
figurines: rubber duck with red hat
ramen: wavy noodles in bowl
teatime: spoon handle; cookies on a plate
```

Export masks from baseline and enhancement:

```bash
cd ~/3DGS/third_party/gaussian-grouping
mkdir -p ~/3DGS/outputs/failure_masks

cp "output/lerf/teatime/test/ours_7000_text/test_mask/0/spoon handle.png" \
  ~/3DGS/outputs/failure_masks/teatime_baseline_spoon_handle_0.png

cp "output/lerf/teatime_densify1500/test/ours_7000_text/test_mask/0/spoon handle.png" \
  ~/3DGS/outputs/failure_masks/teatime_densify1500_spoon_handle_0.png

cp "output/lerf/teatime/test/ours_7000_text/test_mask/0/cookies on a plate.png" \
  ~/3DGS/outputs/failure_masks/teatime_baseline_cookies_on_plate_0.png

cp "output/lerf/teatime_densify1500/test/ours_7000_text/test_mask/0/cookies on a plate.png" \
  ~/3DGS/outputs/failure_masks/teatime_densify1500_cookies_on_plate_0.png
```

Then download:

```powershell
scp -r cse12411723@172.18.35.215:~/3DGS/outputs/failure_masks D:\Downloads\
```

Expected decision:

```text
If the masks are empty or select the wrong object, do prompt/mask tuning.
If masks are correct but boundaries are rough, try more densification or longer training.
```

## Phase 3: Prompt/Mask Tuning

Goal:

```text
Improve weak targets without changing the baseline.
```

Candidate prompt variants:

```text
spoon handle:
  spoon
  metal spoon
  spoon handle

cookies on a plate:
  cookies
  cookies on plate
  cookies on a plate

wavy noodles in bowl:
  noodles
  ramen noodles
  wavy noodles
```

This should be recorded as a new experiment:

```text
teatime_prompt_spoon_7000
teatime_prompt_cookies_7000
```

Do not mix prompt-tuned results into baseline metrics.

Completed prompt test:

```text
cookies on a plate -> cookies:
  IoU 0.2229 -> 0.8948

spoon handle -> spoon:
  IoU 0.0000 -> 0.0000
```

This confirms that prompt tuning is useful for composition-like targets, but the spoon handle case remains unsolved.

Next prompt target for `teatime`:

```bash
cd ~/3DGS
bash scripts/patch_gaussian_grouping_prompt_tuning.sh

bash scripts/render_eval_lerf_prompt_experiment.sh \
  teatime \
  teatime \
  prompt_metal_spoon_7000 \
  0 \
  7000 \
  '{"spoon handle":"metal spoon"}'
```

If this does not improve `spoon handle`, try separate variants:

```bash
bash scripts/render_eval_lerf_prompt_experiment.sh teatime teatime prompt_silver_spoon_7000 0 7000 '{"spoon handle":"silver spoon"}'
bash scripts/render_eval_lerf_prompt_experiment.sh teatime teatime prompt_spoon_handle_object_7000 0 7000 '{"spoon handle":"spoon handle"}'
```

## Phase 4: Optional Densification Trial

Only run this if failure masks are qualitatively correct but boundaries remain rough.

Candidate:

```text
Scene: teatime
Experiment: densify2000_7000
```

Start from `train_12gb_densify1500.json` and change:

```text
densify_until_iter: 2000
```

Risk:

```text
Higher OOM risk on TITAN V 12GB.
```

## Phase 5: Downstream Editing

Goal:

```text
Demonstrate at least one object-level downstream application.
```

Recommended first task:

```text
3D object removal
```

Current status:

```text
figurines/red apple object removal completed as the first downstream result.
Threshold experiments show remaining holes/shadows, so the next downstream step is object inpainting.
```

Use a strong segmentation target first:

```text
figurines: red apple or green apple
ramen: pork belly or egg
teatime: apple or bag of cookies
```

Avoid starting with failed categories such as `spoon handle` or `wavy noodles in bowl`.

Immediate follow-up:

```text
1. Archive removal configs and notes.
2. Keep threshold 0.05 as the most aggressive removal trial, but document remaining artifacts.
3. Move to object inpainting for figurines/red apple.
4. Select representative before/removal/inpainting frames for the final report.
```

## Phase 6: Custom Data

Goal:

```text
Validate the same pipeline on our own real-world scene.
```

Recommended scene:

```text
desktop objects: 2-4 objects, 80-150 phone images, stable lighting
```

Pipeline:

```text
capture images
run COLMAP preprocessing
generate masks
train Gaussian Grouping
render object masks
attempt object removal
```

This should come after the public-data reproduction, enhancement result, and at least one downstream editing demo are cleanly documented.
