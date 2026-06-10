#!/usr/bin/env bash
set -euo pipefail

GG_DIR="${1:-$HOME/3DGS/third_party/gaussian-grouping}"
TARGET="$GG_DIR/edit_object_inpaint.py"

test -f "$TARGET"

python - <<PY
from pathlib import Path

path = Path("$TARGET")
text = path.read_text()

if "if not torch.any(mask2d):" not in text:
    text = text.replace(
        "        mask2d = viewpoint_cam.objects > 128\\n        bbox = mask_to_bbox(mask2d)\\n",
        "        mask2d = viewpoint_cam.objects > 128\\n"
        "        if not torch.any(mask2d):\\n"
        "            continue\\n"
        "        bbox = mask_to_bbox(mask2d)\\n",
    )

lpips_init = """    LPIPS = lpips.LPIPS(net='vgg')
    for param in LPIPS.parameters():
        param.requires_grad = False
    LPIPS.cuda()
"""
if lpips_init in text:
    text = text.replace(lpips_init, "    LPIPS = None\\n")

text = text.replace(
    "lpips_loss = LPIPS(rendering_patches.squeeze()*2-1,gt_patches.squeeze()*2-1).mean()",
    "lpips_loss = torch.zeros((), device=image.device)",
)
text = text.replace(
    "lpips_loss = LPIPS(rendering_patches.squeeze()*2-1, gt_patches.squeeze()*2-1).mean()",
    "lpips_loss = torch.zeros((), device=image.device)",
)
text = text.replace(
    "lpips_loss = torch.zeros((), device=rendering.device)",
    "lpips_loss = torch.zeros((), device=image.device)",
)

path.write_text(text)
print("Applied 12GB inpainting patch to", path)
PY

python -m py_compile "$TARGET"
