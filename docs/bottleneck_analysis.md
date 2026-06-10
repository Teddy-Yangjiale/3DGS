# Bottleneck Analysis

This report summarizes the bottlenecks found so far while reproducing Gaussian Grouping on LERF-MASK under the lab server environment.

## Current Status

We have completed the public-scene baseline on three LERF-MASK scenes:

| Scene | Mean IoU | Boundary Mean IoU | Main Failure Categories |
| --- | ---: | ---: | --- |
| figurines | 0.7630 | 0.7427 | rubber duck with red hat |
| ramen | 0.7620 | 0.6805 | wavy noodles in bowl |
| teatime | 0.6672 | 0.6365 | spoon handle; cookies on a plate |

The current baseline uses:

```text
Method: Gaussian Grouping
GPU: NVIDIA TITAN V, 12GB
resolution scale: -r 1
iterations: 7000
config: configs/gaussian_grouping/train_12gb.json
```

The key low-memory config is:

```json
{
  "densify_until_iter": 1000,
  "num_classes": 256,
  "reg3d_interval": 10,
  "reg3d_k": 5,
  "reg3d_lambda_val": 1,
  "reg3d_max_points": 100000,
  "reg3d_sample_size": 512
}
```

## Main Conclusion

The reproduction pipeline is now functional, but the bottleneck is not a single issue. It is the combination of:

```text
1. Limited GPU memory, which forces early densification stop.
2. Offline server restrictions, which complicate GroundingDINO/BERT/SAM setup.
3. LERF-MASK prompts that include thin, small, or semantically entangled objects.
4. A mismatch between image downsampling and object_mask supervision when using -r 2.
5. Boundary quality limitations, which matter more for downstream editing than RGB reconstruction alone.
```

The baseline is good enough for method reproduction, but not yet optimal for fine-grained object editing.

## 1. Environment Bottlenecks

### 1.1 CUDA Extension Compilation

Gaussian Grouping depends on two CUDA extensions:

```text
diff_gaussian_rasterization
simple_knn
```

Several compilation problems appeared:

```text
ModuleNotFoundError: No module named 'torch'
Unknown CUDA arch (8.9)
unsupported GNU version
crypt.h: No such file or directory
```

Root causes:

```text
1. The initial install was accidentally attempted in the base conda environment using Python 3.13.
2. PyTorch 1.12.1 does not recognize newer default CUDA architecture values.
3. The server system compiler is gcc/g++ 13, while CUDA 11.8 rejects gcc versions later than 11.
4. Python headers needed crypt.h, which was missing from the visible build include path.
```

Fixes:

```text
1. Use a dedicated Python 3.8 environment: gaussian_grouping.
2. Set TORCH_CUDA_ARCH_LIST=7.0 for NVIDIA TITAN V.
3. Install conda gcc/g++ 11 and set CC/CXX/CUDAHOSTCXX.
4. Install libxcrypt/sysroot_linux-64 and expose CONDA_PREFIX/include.
```

Impact:

This is an engineering bottleneck rather than a model-quality bottleneck. Once fixed, training and rendering run normally. However, these patches must be documented because the project is otherwise hard to reproduce on this server.

### 1.2 Runtime Library Path

Training initially failed with:

```text
libcuda.so: cannot open shared object file
```

Root cause:

The conda environment could not find the NVIDIA driver library even though the driver existed on the system.

Fix:

Expose driver and CUDA runtime paths through:

```bash
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:/usr/local/cuda-11.8/lib64:/usr/local/cuda-11.8/targets/x86_64-linux/lib:$LD_LIBRARY_PATH
```

Impact:

This affects every training and rendering command. It is now wrapped by the environment script, but it remains a necessary runtime condition.

## 2. Offline Model Dependency Bottlenecks

`render_lerf_mask.py` requires GroundingDINO, SAM, and BERT. The server cannot access Hugging Face, so online loading failed:

```text
huggingface.co ... Network is unreachable
```

We had to manually upload:

```text
GroundingDINO_SwinB.cfg.py
groundingdino_swinb_cogcoor.pth
bert-base-uncased/config.json
bert-base-uncased/tokenizer_config.json
bert-base-uncased/tokenizer.json
bert-base-uncased/vocab.txt
bert-base-uncased/pytorch_model.bin
```

Then we patched the third-party code so that:

```text
1. GroundingDINO config and weights load from local files.
2. BERT loads from a local directory.
3. A visualization-only supervision annotation call is skipped due to API mismatch.
```

Impact:

This bottleneck affects LERF-MASK evaluation specifically. Standard `render.py` can run without these dependencies, but `eval_lerf_mask.py` needs prompt-level predicted masks, which are generated through `render_lerf_mask.py`.

## 3. Data And Resolution Bottlenecks

We attempted to reduce memory by using:

```text
-r 2
```

This failed with:

```text
target [1, 728, 986], input [1, 256, 364, 493]
```

Root cause:

The RGB image was downsampled, but the `object_mask` target remained at the original resolution.

Impact:

We cannot simply use lower resolution to save memory unless we also resize the object masks or patch the mask loading path. Therefore, all current successful runs use:

```text
-r 1
```

This matters because `-r 1` increases memory pressure on a 12GB GPU. The current low-memory solution is not lower resolution, but earlier densification stop.

## 4. GPU Memory Bottleneck

The official-style training initially failed around 2300-2700 iterations with CUDA OOM.

Root cause:

3DGS training increases the number of Gaussians through densification. More Gaussians improve geometric/detail representation but consume more memory. On TITAN V 12GB, continuing densification too long makes training unstable.

Current mitigation:

```text
densify_until_iter: 1000
iterations: 7000
reg3d_interval: 10
reg3d_max_points: 100000
reg3d_sample_size: 512
```

Impact:

This makes training stable across the three scenes. The tradeoff is reduced Gaussian count and potentially weaker fine details. This likely hurts:

```text
1. thin objects
2. object boundaries
3. partially occluded objects
4. objects that require fine geometry separation
```

The point cloud may look sparse in a normal point-cloud viewer. This does not by itself mean 3DGS rendering failed, because the `.ply` stores Gaussian centers and attributes rather than a dense mesh. However, early densification stop still limits representational capacity.

## 5. Scene-Level Quality Analysis

### 5.1 Figurines

Overall:

```text
Mean IoU: 0.7630
Boundary Mean IoU: 0.7427
```

Strong categories:

```text
red apple: 0.9486
green apple: 0.9222
red toy chair: 0.8979
green toy chair: 0.8646
porcelain hand: 0.8611
```

Weak categories:

```text
rubber duck with red hat: 0.2512
old camera: 0.5955
```

Likely reasons:

The scene has several visually distinctive medium-sized objects, so most classes perform well. The weak duck case may be affected by smaller size, ambiguity in prompt localization, or poor 3D identity consistency under the low-memory Gaussian representation.

Interpretation:

`figurines` is a successful reproduction scene and currently the cleanest result.

### 5.2 Ramen

Overall:

```text
Mean IoU: 0.7620
Boundary Mean IoU: 0.6805
```

Strong categories:

```text
pork belly: 0.9414
egg: 0.9131
yellow bowl: 0.9030
glass of water: 0.8921
chopsticks: 0.8278
```

Weak category:

```text
wavy noodles in bowl: 0.0945
Boundary IoU: 0.0132
```

Likely reasons:

`wavy noodles in bowl` is semantically and visually entangled with the bowl and surrounding food. It is not a clean standalone object. The prompt describes a sub-region inside another object, so both GroundingDINO/SAM and 3D Gaussian grouping can struggle.

Interpretation:

The scene-level Mean IoU remains strong because most objects are good. Boundary IoU is lower because the difficult noodle category has almost no accurate boundary.

### 5.3 Teatime

Overall:

```text
Mean IoU: 0.6672
Boundary Mean IoU: 0.6365
```

Strong categories:

```text
bag of cookies: 0.9479
apple: 0.9050
plate: 0.8712
coffee mug: 0.8510
paper napkin: 0.8271
```

Weak categories:

```text
spoon handle: 0.0000
cookies on a plate: 0.2229
stuffed bear: 0.6426
sheep: 0.6359
```

Likely reasons:

`spoon handle` is a thin, small, partially visible target. It is exactly the type of object that suffers from limited densification and uncertain text-prompt localization. `cookies on a plate` is a composition-like target that overlaps semantically with `plate`, so it is hard to isolate as an independent object group.

Interpretation:

`teatime` is the weakest scene and the best candidate for an enhancement experiment.

## 6. Metric Interpretation

We use:

```text
Mean IoU
Boundary Mean IoU
Per-class IoU
Per-class Boundary IoU
```

Mean IoU measures region overlap. Boundary IoU measures boundary alignment. For downstream editing, Boundary IoU is especially important: a mask with acceptable area overlap but poor boundary alignment can still produce visible artifacts during object removal or inpainting.

Current pattern:

```text
figurines: good region and boundary quality
ramen: good region quality, weaker boundary quality
teatime: weaker region and boundary quality
```

This suggests that the baseline can identify many object regions, but struggles when object boundaries are subtle or objects are nested/entangled.

## 7. Most Important Bottleneck For Next Work

The highest-value next bottleneck is not environment setup anymore. It is:

```text
fine-grained object separation under a 12GB memory budget
```

The current setting stops densification at 1000 iterations to avoid OOM. This likely reduces the model's ability to represent small or thin objects. However, increasing densification may reintroduce OOM.

Therefore, tuning should be done as a separate enhancement experiment, not by replacing the current baseline.

## 8. Downstream Inpainting Bottlenecks

The first `figurines/red apple` object inpainting run completed with:

```text
config: configs/object_inpaint/figurines_red_apple_1000_nolpips.json
output: output/lerf/figurines/train/ours_object_inpaint/iteration_999/
```

The result shows that the target apple can be removed and the missing region can be partially filled. However, the same run also blurs or corrupts background regions and nearby objects.

This reveals a different bottleneck from segmentation:

```text
The inpainting failure is caused less by object-id selection and more by unrestricted 3DGS finetuning with imperfect 2D pseudo labels.
```

### 8.1 Empty Masks

The DEVA/LaMa pipeline produced a fixed number of mask files, but some files contained no white pixels. A fixed file count does not guarantee that each view has a valid target region.

Reasons:

```text
1. Not every view clearly sees the removed apple hole.
2. DEVA may not detect the black/blurry hole in every frame.
3. Some original views are not part of the train-render set and were filled with empty masks.
```

Impact:

The original `edit_object_inpaint.py` assumes every mask is non-empty and crashes when computing `mask_to_bbox`. We patched the script to skip empty-mask views.

### 8.2 LPIPS Memory And Patch-Size Issues

The original inpainting script computes LPIPS even when the configured weight is zero. On the 12GB TITAN V, this adds unnecessary VGG memory cost. Thin masks can also produce small bounding boxes, causing VGG pooling to fail.

Mitigation for the first stable run:

```text
lambda_dlpips: 0.0
LPIPS initialization disabled
lpips_loss set to zero
```

This makes the first run stable but also means the loss is L1-only, which can increase blur.

### 8.3 Multi-View Inconsistency

LaMa is a 2D image inpainting method. It repairs each rendered frame independently and does not enforce multi-view consistency. When the 3DGS model is finetuned against these frame-wise pseudo labels, it tries to fit inconsistent target appearances across views.

Impact:

```text
1. The removed region may become less black.
2. The surrounding tabletop may become blurry.
3. Nearby objects and background may degrade.
```

### 8.4 Full-Scene Finetuning

The most important inpainting bottleneck is the optimization scope. The first successful run still updates the 3DGS scene too broadly. Since the pseudo labels are imperfect, unrelated Gaussians can receive harmful gradients and the background can be damaged.

Recommended fix:

```text
Use localized masked finetuning:
1. compute loss only inside the inpainting mask or expanded local bbox,
2. preserve the original RGB outside the target area,
3. optionally freeze non-target Gaussians or restrict trainable parameters.
```

This should be treated as the next method enhancement because it directly addresses the observed degradation rather than only changing iteration count.

Recommended tuning target:

```text
Scene: teatime
Objects: spoon handle, cookies on a plate
```

Recommended experiment:

```text
Baseline:
  densify_until_iter = 1000
  iterations = 7000

Completed Trial A:
  densify_until_iter = 1500
  iterations = 7000
  reg3d_max_points = 50000
  reg3d_sample_size = 256

Result:
  Mean IoU: 0.6672 -> 0.7108
  Boundary Mean IoU: 0.6365 -> 0.6768

Remaining issue:
  spoon handle stayed at 0.0000
  cookies on a plate stayed near 0.22
```

Evaluation:

```text
1. Compare overall Mean IoU and Boundary Mean IoU.
2. Compare per-class IoU for spoon handle and cookies on a plate.
3. Inspect rendered masks qualitatively to determine whether the failure is from GroundingDINO/SAM prompt localization or from 3D grouping.
```

## 8. Practical Risks

### 8.1 Symlink And Evaluation Path Confusion

`render_lerf_mask.py` writes masks under:

```text
output/lerf/<scene>/test/ours_7000_text/test_mask/
```

`eval_lerf_mask.py` expects:

```text
result/lerf_mask/<scene>/
```

We use symlinks to connect these paths. Some shell checks reported `wc -l` as `0` even though evaluation read valid files. Before final packaging, we should verify the symlinks with:

```bash
readlink -f result/lerf_mask/<scene>
find "$(readlink -f result/lerf_mask/<scene>)" -type f | wc -l
```

### 8.2 Third-Party Patch Drift

We patched third-party files for offline operation and API compatibility. These changes live inside `third_party/gaussian-grouping`, which is not committed to this repository. The reproducible version of these modifications should be preserved through:

```text
scripts/patch_gaussian_grouping_offline.sh
docs/reproduction.md
```

Before final submission, rerun the patch script on a fresh clone to confirm it still applies.

## 9. Summary

The current project is past the initial engineering setup stage. The completed three-scene LERF-MASK baseline demonstrates that Gaussian Grouping can be reproduced on the lab server with a constrained 12GB GPU.

The main remaining bottleneck is quality on difficult object categories:

```text
thin object: spoon handle
entangled object: wavy noodles in bowl
composition target: cookies on a plate
small/ambiguous object: rubber duck with red hat
```

These failures are valuable rather than purely negative: they identify where parameter tuning and downstream editing validation should focus.

The densify1500 experiment confirms that more densification can improve overall segmentation under the 12GB budget, but it does not fix the hardest prompt-level failures. The next bottleneck to address is prompt and mask-selection quality for thin or semantically entangled targets.

The first hardcoded prompt-tuning experiment on `teatime` changed `cookies on a plate` to query `cookies`. This improved `cookies on a plate` from `0.2229` to `0.8948`, and improved scene-level Mean IoU from `0.6672` to `0.7344`. This is direct evidence that at least one major failure was caused by text-prompt localization rather than 3D Gaussian representation.

The same experiment changed `spoon handle` to query `spoon`, but the IoU remained `0.0000`. This indicates that the spoon handle failure is harder: it may require a different prompt, lower detection threshold, local mask selection, or manual validation.
