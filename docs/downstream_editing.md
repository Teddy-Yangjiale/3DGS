# Downstream Editing

This page records downstream applications built on top of segmented 3D Gaussians.

## Object Removal: Figurines Red Apple

Status:

```text
completed initial run
```

Scene:

```text
LERF-MASK / figurines
```

Target object:

```text
red apple
```

Reason for choosing this object:

```text
red apple has strong segmentation quality in the baseline:
Mean IoU: 0.9486
Boundary IoU: 0.9063
```

Selected Gaussian object id:

```text
select_obj_id = [1]
```

Config:

```text
configs/object_removal/figurines_red_apple.json
```

Expected config content:

```json
{
  "num_classes": 256,
  "removal_thresh": 0.3,
  "select_obj_id": [1]
}
```

Server command:

```bash
conda activate gaussian_grouping
cd ~/3DGS/third_party/gaussian-grouping
source ~/3DGS/scripts/env_gaussian_grouping.sh

CUDA_VISIBLE_DEVICES=0 python edit_object_removal.py \
  -m output/lerf/figurines \
  --config_file ~/3DGS/configs/object_removal/figurines_red_apple.json \
  --iteration 7000 \
  --skip_test
```

Output:

```text
output/lerf/figurines/point_cloud_object_removal/iteration_7000/point_cloud.ply
output/lerf/figurines/train/ours_object_removal/iteration_7000/concat/
output/lerf/figurines/train/ours_object_removal/iteration_7000/renders/
```

Report export path:

```text
~/3DGS/outputs/object_removal/figurines_red_apple/
  concat/
  renders/
```

Notes:

The first run with `--skip_train` generated the edited point cloud but failed during test-view video composition because the test view list was empty in that code path. Running with `--skip_test` rendered train views successfully.

The OpenCV warning about `DIVX` fallback is not a failure. The PNG frames were generated correctly and can be used directly or converted to mp4 with ffmpeg.

## Next Editing Steps

1. Inspect `concat/` frames and choose representative before/after examples.
2. Generate an mp4 from `concat/*.png`.
3. Add selected images/video to the final report.
4. Optionally repeat object removal for another high-IoU object, such as `ramen/pork belly` or `teatime/apple`.

