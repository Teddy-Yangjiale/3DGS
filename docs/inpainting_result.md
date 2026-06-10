# Object Inpainting Result

This page records the first completed 3D object inpainting run for `figurines/red apple`.

## Goal

```text
Remove the red apple from the figurines scene and fill the missing tabletop region.
```

The starting point is the completed object removal result:

```text
output/lerf/figurines/train/ours_object_removal/iteration_7000/
```

The removal result deletes the apple body but leaves visible holes, black artifacts, and shadow-like residue. This motivates object inpainting.

## Pipeline

The completed inpainting pipeline is:

```text
1. Render object-removal views.
2. Use DEVA with text prompt to detect the missing/black-hole region.
3. Prepare LaMa inputs from removal renders and DEVA masks.
4. Run LaMa 2D inpainting.
5. Convert LaMa outputs into pseudo labels aligned with the original LERF-MASK image names.
6. Generate compatible inpaint masks for Gaussian Grouping.
7. Finetune the 3DGS scene with edit_object_inpaint.py.
8. Render the inpainted 3DGS result.
```

## Implemented Fixes

Several modifications were required to make the inpainting pipeline run on the lab server.

### DEVA Offline Loading

The inpainting-mask stage uses a separate DEVA/GroundingDINO loading path from `render_lerf_mask.py`. The server cannot access Hugging Face, so `scripts/patch_deva_inpainting_offline.sh` patches:

```text
Tracking-Anything-with-DEVA/deva/ext/ext_eval_args.py
Tracking-Anything-with-DEVA/Grounded-Segment-Anything/GroundingDINO/groundingdino/util/get_tokenlizer.py
Tracking-Anything-with-DEVA/deva/inference/result_utils.py
```

This forces GroundingDINO and BERT to load from:

```text
~/3DGS/checkpoints/groundingdino/
~/3DGS/checkpoints/bert-base-uncased/
```

It also avoids a `supervision` annotation API mismatch.

### Pseudo-Label Alignment

LaMa produced 299 inpainted training-view images:

```text
lama/output/lerf/figurines_red_apple/label/00000.png ... 00298.png
```

The original scene contains 303 images:

```text
data/lerf/figurines/images/frame_*.jpg
```

We therefore built a full 303-image pseudo-label directory by matching train-render `gt/*.png` images back to the original `frame_*.jpg` names. The 299 LaMa outputs replace the corresponding original frames, while the remaining four images use the original RGB image.

### Mask Compatibility

Gaussian Grouping image names and mask names do not use the same extension convention in all code paths. To avoid missing-mask reads, the inpaint object-mask directory contains both naming formats:

```text
frame_00001.png
frame_00001.jpg.png
```

The active object path is:

```text
object_mask_inpaint_unseen_compat
```

### Empty-Mask Handling

Some views have valid mask files but no white pixels. This happens because not every view sees the removed apple hole clearly, and DEVA does not detect an inpainting region in every rendered view.

The original `edit_object_inpaint.py` assumes every mask is non-empty and crashes in `mask_to_bbox`. We patched it to skip empty-mask views before computing the bounding box.

### LPIPS Disabled

The original script computes LPIPS even when the configured weight is zero. On a 12GB TITAN V this can cause CUDA OOM, and thin masks can produce patches that are too small for VGG pooling.

For the first stable run, LPIPS was force-disabled:

```text
lambda_dlpips: 0.0
LPIPS initialization skipped
lpips_loss set to zero
```

The first successful config is:

```text
configs/object_inpaint/figurines_red_apple_1000_nolpips.json
```

These local modifications can be reapplied with:

```bash
cd ~/3DGS
bash scripts/patch_gaussian_grouping_inpaint_12gb.sh
```

## First Successful Run

Config:

```json
{
  "num_classes": 256,
  "removal_thresh": 0.05,
  "select_obj_id": [1],
  "images": "images_inpaint_unseen",
  "object_path": "object_mask_inpaint_unseen_compat",
  "r": 1,
  "lambda_dlpips": 0.0,
  "finetune_iteration": 1000
}
```

Output:

```text
output/lerf/figurines/point_cloud_object_inpaint/iteration_999/point_cloud.ply
output/lerf/figurines/train/ours_object_inpaint/iteration_999/renders/
output/lerf/figurines/train/ours_object_inpaint/iteration_999/concat/
```

Status:

```text
completed
```

## Qualitative Result

Observed improvement:

```text
The red apple is removed and the missing area is partially filled.
```

Observed limitation:

```text
The inpainted region still contains blur and small dark artifacts.
More importantly, the background and nearby objects are also degraded or blurred.
```

Interpretation:

```text
The inpainting pipeline is functional, but the naive full-scene finetuning strategy is too destructive.
```

## Root Cause Of Degraded Background

The current inpainting finetune uses frame-wise LaMa pseudo labels and updates the 3DGS scene. LaMa outputs are not multi-view consistent, and the original finetuning script does not tightly restrict optimization to only the removed-object region.

As a result, the optimization can affect:

```text
background Gaussians
other object appearance
tabletop texture
global sharpness
```

This is why the apple can disappear while unrelated regions become blurry or corrupted.

## Evaluation Criteria

There is no ground-truth image for the hidden tabletop behind the apple, so this downstream task is evaluated qualitatively:

```text
1. Target removal: the red apple should disappear.
2. Hole reduction: black holes and missing-region artifacts should be reduced.
3. Local consistency: the filled region should look like the surrounding tabletop.
4. Background preservation: unrelated objects and background should remain sharp.
5. Multi-view consistency: the filled region should not flicker or change drastically across views.
```

Current judgment:

```text
Target removal: improved
Hole reduction: partially improved
Background preservation: poor
Overall: pipeline success, quality limited
```

## Next Improvement Direction

Do not simply increase finetune iterations. Longer full-scene finetuning may further damage the background.

The next method improvement should be localized masked finetuning:

```text
1. Compute loss only inside the inpainting mask or an expanded local bbox.
2. Preserve the original image outside the target region.
3. Optionally freeze non-target Gaussians or only optimize selected parameters.
4. Use mask dilation carefully to cover residual shadows without touching unrelated objects.
```

This is a stronger contribution than simply running more iterations because it directly addresses the observed failure mode.
