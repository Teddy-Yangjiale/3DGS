# Project Plan

## Goal

Reproduce object-level segmentation in 3D Gaussian Splatting and validate downstream editing on public scenes and one custom captured scene.

## Method

Primary method: Gaussian Grouping.

Repository: https://github.com/lkeab/gaussian-grouping

Reason: it directly supports 3DGS object segmentation, object removal, inpainting, style transfer, and multi-object editing.

## Public Scenes

Minimum required scenes:

1. LERF-Mask `figurines`
2. LERF-Mask `ramen`
3. LERF-Mask `teatime`

Optional additional scene:

- Mip-NeRF360 `counter` or `kitchen`

## Data Layout

```text
data/
  lerf_mask/
  mipnerf360/
  custom/
outputs/
  public/
  custom/
checkpoints/
logs/
```

Large files stay out of Git. Git tracks scripts, configs, notes, and report files only.

## Milestones

1. Server environment
   - Login through SSH.
   - Create `/data2/$USER/3DGS`.
   - Clone this repository.
   - Clone `gaussian-grouping` under `third_party/`.
   - Build CUDA extensions.

2. Public data reproduction
   - Download LERF-Mask scenes. Completed.
   - Run segmentation rendering for three scenes.
   - Record IoU and Boundary-IoU if official annotations are available.
   - `figurines` completed: Mean IoU 0.7630, Boundary Mean IoU 0.7427.
   - `ramen` completed: Mean IoU 0.7620, Boundary Mean IoU 0.6805.
   - `teatime` completed: Mean IoU 0.6672, Boundary Mean IoU 0.6365.
   - Three-scene baseline is complete; next step is parameter tuning on representative failure cases.

3. Downstream editing
   - Run object removal on at least one scene.
   - Attempt inpainting or multi-object editing.
   - Save before/after rendered images and videos.

4. Custom data validation
   - Capture 80-150 phone images around a small tabletop scene.
   - Run COLMAP preprocessing.
   - Generate masks with the method pipeline.
   - Train segmentation and render results.

5. Contribution
   - Tune mask filtering or segmentation parameters after the three-scene baseline is complete.
   - Compare before/after outputs qualitatively.
   - Record failure cases.

6. Report
   - Environment and commands.
   - Dataset table.
   - Segmentation results.
   - Bottleneck analysis.
   - Editing results.
   - Custom data result.
   - Enhancement and analysis.
