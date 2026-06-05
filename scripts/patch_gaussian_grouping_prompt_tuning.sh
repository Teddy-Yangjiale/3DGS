#!/usr/bin/env bash
set -euo pipefail

GG_DIR="${1:-$HOME/3DGS/third_party/gaussian-grouping}"

cd "$GG_DIR"

python - <<'PY'
from pathlib import Path

path = Path("render_lerf_mask.py")
text = path.read_text()

if "prompt_tuning_patch_applied" in text:
    print("Prompt tuning patch already applied.")
    raise SystemExit(0)

text = text.replace(
    "import cv2\n",
    "import cv2\nimport json\n# prompt_tuning_patch_applied\n"
)

text = text.replace(
    "def render_set(model_path, name, iteration, views, gaussians, pipeline, background, classifier, groundingdino_model, sam_predictor, TEXT_PROMPT, threshold=0.2):",
    "def render_set(model_path, name, iteration, views, gaussians, pipeline, background, classifier, groundingdino_model, sam_predictor, TEXT_PROMPT, QUERY_PROMPT=None, output_tag=None, threshold=0.2):"
)

text = text.replace(
    '''    render_path = os.path.join(model_path, name, "ours_{}_text".format(iteration), "renders")
    gts_path = os.path.join(model_path, name, "ours_{}_text".format(iteration), "gt")
    colormask_path = os.path.join(model_path, name, "ours_{}_text".format(iteration), "objects_feature16")
    pred_obj_path = os.path.join(model_path, name, "ours_{}_text".format(iteration), "test_mask")
''',
    '''    output_name = "ours_{}_text".format(iteration) if output_tag is None else output_tag
    query_prompt = TEXT_PROMPT if QUERY_PROMPT is None else QUERY_PROMPT
    render_path = os.path.join(model_path, name, output_name, "renders")
    gts_path = os.path.join(model_path, name, output_name, "gt")
    colormask_path = os.path.join(model_path, name, output_name, "objects_feature16")
    pred_obj_path = os.path.join(model_path, name, output_name, "test_mask")
'''
)

text = text.replace(
    "    text_mask, annotated_frame_with_mask = grouned_sam_output(groundingdino_model, sam_predictor, TEXT_PROMPT, image)\n",
    "    text_mask, annotated_frame_with_mask = grouned_sam_output(groundingdino_model, sam_predictor, query_prompt, image)\n"
)

text = text.replace(
    "    Image.fromarray(annotated_frame_with_mask).save(os.path.join(render_path[:-8],'grounded-sam---'+TEXT_PROMPT+'.png'))\n",
    "    Image.fromarray(annotated_frame_with_mask).save(os.path.join(render_path[:-8],'grounded-sam---'+TEXT_PROMPT+'---query---'+query_prompt+'.png'))\n"
)

text = text.replace(
    "def render_sets(dataset : ModelParams, iteration : int, pipeline : PipelineParams, skip_train : bool, skip_test : bool):",
    "def render_sets(dataset : ModelParams, iteration : int, pipeline : PipelineParams, skip_train : bool, skip_test : bool, prompt_overrides=None, output_tag=None):"
)

text = text.replace(
    '''    print("Text prompts: ", positives)
    for TEXT_PROMPT in positives:
        if not skip_train:
            render_set(dataset.model_path, "train", scene.loaded_iter, scene.getTrainCameras(), gaussians, pipeline, background, classifier, groundingdino_model, sam_predictor, TEXT_PROMPT)
        if not skip_test:
            render_set(dataset.model_path, "test", scene.loaded_iter, scene.getTestCameras(), gaussians, pipeline, background, classifier, groundingdino_model, sam_predictor, TEXT_PROMPT)
''',
    '''    prompt_overrides = prompt_overrides or {}
    print("Text prompts: ", positives)
    print("Prompt overrides: ", prompt_overrides)
    for TEXT_PROMPT in positives:
        QUERY_PROMPT = prompt_overrides.get(TEXT_PROMPT, TEXT_PROMPT)
        if not skip_train:
            render_set(dataset.model_path, "train", scene.loaded_iter, scene.getTrainCameras(), gaussians, pipeline, background, classifier, groundingdino_model, sam_predictor, TEXT_PROMPT, QUERY_PROMPT, output_tag)
        if not skip_test:
            render_set(dataset.model_path, "test", scene.loaded_iter, scene.getTestCameras(), gaussians, pipeline, background, classifier, groundingdino_model, sam_predictor, TEXT_PROMPT, QUERY_PROMPT, output_tag)
'''
)

text = text.replace(
    '''    parser.add_argument("--skip_test", action="store_true")
    parser.add_argument("--quiet", action="store_true")
    args = get_combined_args(parser)
''',
    '''    parser.add_argument("--skip_test", action="store_true")
    parser.add_argument("--prompt_overrides", default="", type=str)
    parser.add_argument("--output_tag", default="", type=str)
    parser.add_argument("--quiet", action="store_true")
    args = get_combined_args(parser)
'''
)

text = text.replace(
    '''    print("Rendering " + args.model_path)
    # Initialize system state (RNG)
    safe_state(args.quiet)
    render_sets(model.extract(args), args.iteration, pipeline.extract(args), args.skip_train, args.skip_test)
''',
    '''    print("Rendering " + args.model_path)
    prompt_overrides = json.loads(args.prompt_overrides) if args.prompt_overrides else {}
    output_tag = args.output_tag if args.output_tag else None
    # Initialize system state (RNG)
    safe_state(args.quiet)
    render_sets(model.extract(args), args.iteration, pipeline.extract(args), args.skip_train, args.skip_test, prompt_overrides, output_tag)
'''
)

path.write_text(text)
print("Prompt tuning patch applied to render_lerf_mask.py")
PY

python -m py_compile render_lerf_mask.py
