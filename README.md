# AIML Golden Notebook Image

This repository builds the **golden, pinned, GPU-enabled Jupyter notebook image**
used across AIML projects.

The image is:
- CUDA **12.2** (runtime, cuDNN 8)
- Python **3.10.13** (via `uv`)
- Fully pinned ML / DL / CV stack (Torch, TensorFlow, ONNX, OpenCV, FAISS, etc.)
- JupyterLab-based, Kubeflow / JupyterHub compatible
- Debug-friendly (faulthandler + core dumps)
- Reproducible and Harbor-ready

---
## Tagging Convention

Tags must be **explicit and immutable**, and folder inside `dists`.

Recommended format:
```
cuda12.2-py3.10-tf2.15-torch2.1.2-faiss1.9.0.0
```

Rules:
- Do NOT use `latest`
- Do NOT retag existing images
- New build = new tag


## Build Requirements

- Docker Engine **24.0.x**
- NVIDIA Container Runtime
- Git access to this repository
- Network access to:
  - PyPI
  - PyTorch CUDA wheel index
  - Docker Registry


## Build Command (GitHub / CI)

Run from the **repository root**:

```bash
docker build
  -t lokeshkurre/notebooks:cuda12.2-py3.10-tf2.15-torch2.1.2-faiss1.9.0.0 \
  -f dists/cuda12.2-py3.10-tf2.15-torch2.1.2-faiss1.9.0.0/Dockerfile .
```

## Push to Registry
```
docker push lokeshkurre/notebooks:cuda12.2-py3.10-tf2.15-torch2.1.2-faiss1.9.0.0
```

## Runtime Validation

Run inside a notebook terminal:
```
nvidia-smi
python -c "import torch; print(torch.cuda.is_available())"
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
python -c "import cv2; print(cv2.__version__)"
```

On shell startup, the image also prints:
- OS version
- Python + virtualenv info
- GPU visibility
- Torch / TensorFlow / ONNX Runtime status

## Important Notes

- CUDA is pinned via base image
  - Do NOT install or upgrade CUDA via apt, conda, or pip
- All Python dependencies are pinned via constraints
- Any dependency change requires a new image tag
- This image is infrastructure, not a project sandbox

## VS Code Web Distribution

This repository also includes a VS Code browser-serving image in:

```text
dists/vscode-web/
```

It uses `s6-overlay` services and starts VS Code via `code serve-web` behind nginx.

Default pinned values in that distro:

- `VSCODE_VERSION=1.124.2`
- `VSCODE_GIT_HASH=6928394f91b684055b873eecb8bc281365131f1c`

Build argument source:

- `build_arg.properties` holds Docker build args used by the local build flow.
- `make build-vscode-web` reads this file and expands each entry as `--build-arg KEY=VALUE`.
- Keep entries as plain `KEY=VALUE` lines (inline comments are allowed).

Build example:

```bash
docker build \
  -t lokeshkurre/notebooks:vscode-web-1.124.2 \
  -f dists/vscode-web/Dockerfile .
```

Makefile shortcut:

```bash
make build-vscode-web
```

Optional build args:

```bash
--build-arg BUILD_TYPE=gpu \
--build-arg BUILD_MODE=dev \
--build-arg VSCODE_VERSION=1.124.2 \
--build-arg VSCODE_GIT_HASH=6928394f91b684055b873eecb8bc281365131f1c
```

Runtime behavior:

- VS Code web server listens on `8887` internally.
- nginx fronts services on `${SVC_PORT:-8888}` with `${NB_PREFIX:-/}` routing.
- Base path is passed through `--server-base-path` from normalized `NB_PREFIX`.
- VS Code extensions are preinstalled from `dists/vscode-web/vscode-extensions.txt`.
- Connect proxy (`${NB_PREFIX}/connect/<ip:port>/<path>`) is gated by `ENABLE_CONNECT_PROXY` (default: `1`). Set `ENABLE_CONNECT_PROXY=0` to disable it.
- nginx TLS policy is `TLSv1.2 TLSv1.3`.

For detailed internals and upgrade steps, see:

- `docs/serve-vscode-on-web.md`
