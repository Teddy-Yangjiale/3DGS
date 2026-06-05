# Parameter Notes

## JSON Parameters

`train.py` reads only the following keys from `--config_file`:

```text
densify_until_iter
num_classes
reg3d_interval
reg3d_k
reg3d_lambda_val
reg3d_max_points
reg3d_sample_size
```

Other settings, such as `iterations`, `data_device`, `densification_interval`, and `densify_grad_threshold`, must be passed as command-line arguments.

## Current 12GB Config

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

This config is conservative. It reduces memory by stopping densification early and lowering 3D regularization cost.

## Effective Command-Line Parameters

The completed `figurines` run used:

```text
-r 1
--iterations 7000
--test_iterations 1000 7000
--save_iterations 1000 7000
```

Potential next low-memory additions:

```text
--data_device cpu
--densification_interval 200
--densify_grad_threshold 0.0005
```

These should be passed on the command line, not placed in JSON.

