#!/usr/bin/env bash
set -euo pipefail

GG_DIR="${1:-$HOME/3DGS/third_party/gaussian-grouping}"
GROUNDING_DIR="${2:-$HOME/3DGS/checkpoints/groundingdino}"
BERT_DIR="${3:-$HOME/3DGS/checkpoints/bert-base-uncased}"

DEVA_DIR="$GG_DIR/Tracking-Anything-with-DEVA"
GROUNDINGDINO_DIR="$DEVA_DIR/Grounded-Segment-Anything/GroundingDINO"

test -d "$DEVA_DIR"
test -d "$GROUNDINGDINO_DIR"
test -f "$GROUNDING_DIR/GroundingDINO_SwinB.cfg.py"
test -f "$GROUNDING_DIR/groundingdino_swinb_cogcoor.pth"
test -f "$BERT_DIR/config.json"
test -f "$BERT_DIR/pytorch_model.bin"
test -f "$BERT_DIR/tokenizer_config.json"
test -f "$BERT_DIR/vocab.txt"

python - <<PY
from pathlib import Path
import re

gg = Path("$GG_DIR")
deva = Path("$DEVA_DIR")
grounding = Path("$GROUNDING_DIR")
bert = Path("$BERT_DIR")

local_cfg = grounding / "GroundingDINO_SwinB.local.deva.cfg.py"
cfg_text = (grounding / "GroundingDINO_SwinB.cfg.py").read_text()
cfg_text = cfg_text.replace(
    'text_encoder_type = "bert-base-uncased"',
    f'text_encoder_type = "{bert}"',
)
local_cfg.write_text(cfg_text)

grounding_dino_py = deva / "deva/ext/grounding_dino.py"
text = grounding_dino_py.read_text()

replacements = {
    "GROUNDING_DINO_CONFIG_PATH": str(local_cfg),
    "GROUNDING_DINO_CHECKPOINT_PATH": str(grounding / "groundingdino_swinb_cogcoor.pth"),
}

patched = text
for name, value in replacements.items():
    patched, n = re.subn(
        rf'^{name}\\s*=\\s*["\\\'].*?["\\\']\\s*$',
        f'{name} = "{value}"',
        patched,
        flags=re.M,
    )
    if n == 0:
        raise SystemExit(f"Could not patch {name} in {grounding_dino_py}")

grounding_dino_py.write_text(patched)

tokenizer_file = deva / "Grounded-Segment-Anything/GroundingDINO/groundingdino/util/get_tokenlizer.py"
tok_text = tokenizer_file.read_text()
tok_text = tok_text.replace(
    'if text_encoder_type == "bert-base-uncased":',
    'if text_encoder_type == "bert-base-uncased" or text_encoder_type.startswith("/"):',
)
tokenizer_file.write_text(tok_text)

print("DEVA offline inpainting patch applied.")
print(f"GroundingDINO config: {local_cfg}")
print(f"GroundingDINO checkpoint: {grounding / 'groundingdino_swinb_cogcoor.pth'}")
print(f"BERT path: {bert}")
PY

python -m py_compile "$DEVA_DIR/deva/ext/grounding_dino.py"
python -m py_compile "$GROUNDINGDINO_DIR/groundingdino/util/get_tokenlizer.py"
