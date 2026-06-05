#!/usr/bin/env bash
set -euo pipefail

GG_DIR="${1:-$HOME/3DGS/third_party/gaussian-grouping}"
GROUNDING_DIR="${2:-$HOME/3DGS/checkpoints/groundingdino}"
BERT_DIR="${3:-$HOME/3DGS/checkpoints/bert-base-uncased}"

cd "$GG_DIR"

test -f "$GROUNDING_DIR/GroundingDINO_SwinB.cfg.py"
test -f "$GROUNDING_DIR/groundingdino_swinb_cogcoor.pth"
test -f "$BERT_DIR/config.json"
test -f "$BERT_DIR/pytorch_model.bin"

python - <<PY
from pathlib import Path
import re

gg = Path("$GG_DIR")
grounding = Path("$GROUNDING_DIR")
bert = Path("$BERT_DIR")

grounded_sam = gg / "ext" / "grounded_sam.py"
text = grounded_sam.read_text()

new_func = '''def load_model_hf(repo_id, filename, ckpt_config_filename, device='cpu'):
    if os.path.exists(ckpt_config_filename):
        cache_config_file = ckpt_config_filename
    else:
        cache_config_file = hf_hub_download(repo_id=repo_id, filename=ckpt_config_filename)

    args = SLConfig.fromfile(cache_config_file)
    model = build_model(args)
    args.device = device

    if os.path.exists(filename):
        cache_file = filename
    else:
        cache_file = hf_hub_download(repo_id=repo_id, filename=filename)

    checkpoint = torch.load(cache_file, map_location='cpu')
    log = model.load_state_dict(clean_state_dict(checkpoint['model']), strict=False)
    print("Model loaded from {} => {}".format(cache_file, log))
    _ = model.eval()
    return model

'''

text2 = re.sub(r"def load_model_hf\\(.*?\\n(?=def show_mask)", new_func, text, flags=re.S)
if text2 == text:
    raise SystemExit("Could not patch load_model_hf in ext/grounded_sam.py")

text2 = text2.replace(
    '''    annotated_frame = annotate(image_source=image_source, boxes=boxes, logits=logits, phrases=phrases)
    annotated_frame = annotated_frame[...,::-1] # BGR to RGB
''',
    '''    # Skip visualization annotation because supervision APIs differ by version.
    annotated_frame = image_source.copy()
'''
)
grounded_sam.write_text(text2)

render_file = gg / "render_lerf_mask.py"
text = render_file.read_text()
text = text.replace(
    'ckpt_filenmae = "groundingdino_swinb_cogcoor.pth"',
    f'ckpt_filenmae = "{grounding / "groundingdino_swinb_cogcoor.pth"}"'
)
text = text.replace(
    'ckpt_config_filename = "GroundingDINO_SwinB.cfg.py"',
    f'ckpt_config_filename = "{grounding / "GroundingDINO_SwinB.local.cfg.py"}"'
)
render_file.write_text(text)

local_cfg = grounding / "GroundingDINO_SwinB.local.cfg.py"
cfg_text = (grounding / "GroundingDINO_SwinB.cfg.py").read_text()
cfg_text = cfg_text.replace(
    'text_encoder_type = "bert-base-uncased"',
    f'text_encoder_type = "{bert}"'
)
local_cfg.write_text(cfg_text)

tokenizer_file = gg / "Tracking-Anything-with-DEVA/Grounded-Segment-Anything/GroundingDINO/groundingdino/util/get_tokenlizer.py"
tok_text = tokenizer_file.read_text()
tok_text = tok_text.replace(
    'if text_encoder_type == "bert-base-uncased":',
    'if text_encoder_type == "bert-base-uncased" or text_encoder_type.startswith("/"):'
)
tokenizer_file.write_text(tok_text)

print("Offline patch applied.")
PY

python -m py_compile ext/grounded_sam.py

