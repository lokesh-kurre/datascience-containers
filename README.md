# AIML Golden Notebook Image

Golden developer notebook container used across AIML projects.

The image provides a stable ML engineering environment with:

- Ubuntu base image
- Python managed by `uv`
- VS Code Web
- Jupyter Notebook
- Docker/Kubernetes tooling
- Data engineering libraries
- Scientific Python stack
- Optional CUDA development layer

This image is designed as a **platform image**, not a project dependency bundle.

Project-specific dependencies such as:

- PyTorch
- TensorFlow
- JAX
- Transformers
- vLLM
- DeepSpeed

should live inside project virtual environments.

---

# Architecture

```text
ubuntu
  |
  +-- base tools
        |
        +-- python + uv
              |
              +-- vscode + jupyter
                    |
                    +-- final-cpu
                          |
                          +-- final-gpu
                                |
                                +-- CUDA headers
                                +-- nvcc
                                +-- nvrtc
                                +-- build libraries
```

CPU and GPU images share all common Docker layers.

The GPU image only adds CUDA compilation support.

---

# Image Variants

## CPU Image

Docker target:

```text
final-cpu
```

Includes:

- Python
- uv
- Jupyter
- VS Code Web
- build tools
- OpenCV CPU
- NumPy/SciPy ecosystem
- database clients
- cloud SDKs
- profiling utilities

---

## GPU Image

Docker target:

```text
final-gpu
```

Extends:

```text
final-cpu
```

Additional CUDA packages:

```text
cuda-minimal-build
cuda-cudart-dev
cuda-nvrtc-dev
cuda-nvml-dev
libcublas-dev
libcusparse-dev
libcurand-dev
libcusolver-dev
```

Provides:

- CUDA headers
- nvcc compiler
- CUDA extension builds
- custom CUDA kernel compilation

The image intentionally does not globally install:

- torch
- tensorflow
- jax
- transformers

Framework CUDA runtimes are managed by project environments.

Example:

```bash
uv pip install torch
```

PyTorch manages its own:

- CUDA runtime
- cuDNN
- NCCL
- CUDA libraries

---

# Build Configuration

Build arguments are stored in:

```text
build_arg.properties
```

Example:

```properties
UBUNTU_VERSION=22.04

PYTHON_VERSION=3.11

VSCODE_VERSION=1.125.1
VSCODE_GIT_HASH=fcf604774b9f2674b473065736ee75077e256353

S6_OVERLAY_VERSION=3.2.3.0

CUDA_MAJOR=12
CUDA_MINOR=2
```

Keep format:

```text
KEY=VALUE
```

---

# Build

## CPU

```bash
make build-cpu
```

Image:

```text
lokeshkurre/vscode-web:ubuntu22.04-py3.11-cpu
```

---

## GPU

```bash
make build-gpu
```

Image:

```text
lokeshkurre/vscode-web:ubuntu22.04-py3.11-cuda12.2
```

---

# Manual Docker Build

CPU:

```bash
docker build \
  --target final-cpu \
  -t notebook:cpu \
  -f dists/vscode-web/Dockerfile .
```

GPU:

```bash
docker build \
  --target final-gpu \
  -t notebook:gpu \
  -f dists/vscode-web/Dockerfile .
```

---

# Tagging Convention

Images use explicit immutable tags.

Format:

```text
ubuntu<version>-py<version>-<variant>
```

Examples:

CPU:

```text
ubuntu22.04-py3.11-cpu
```

GPU:

```text
ubuntu22.04-py3.11-cuda12.2
```

Rules:

- Do not use `latest`
- Do not overwrite released tags
- Dependency baseline change requires a new tag

---

# Build Metadata

Images contain OCI labels.

Standard labels:

```text
org.opencontainers.image.source
org.opencontainers.image.revision
org.opencontainers.image.created
org.opencontainers.image.version
```

Platform labels:

```text
ai.platform.cuda.enabled
ai.platform.cuda.version
ai.platform.cuda.mode
```

Inspect:

```bash
docker inspect IMAGE \
  --format '{{json .Config.Labels}}' | jq
```

Example:

```json
{
  "org.opencontainers.image.revision": "a91bc22",
  "ai.platform.cuda.enabled": "true",
  "ai.platform.cuda.version": "12.2",
  "ai.platform.cuda.mode": "compile-only"
}
```

---

# Runtime

## CPU

```bash
docker run \
  -it \
  --rm \
  lokeshkurre/vscode-web:ubuntu22.04-py3.11-cpu
```

---

## GPU

```bash
docker run \
  -it \
  --rm \
  --gpus all \
  lokeshkurre/vscode-web:ubuntu22.04-py3.11-cuda12.2
```

---

# GPU Validation

Driver:

```bash
nvidia-smi
```

CUDA compiler:

```bash
nvcc --version
```

Framework test:

```bash
python -c "import torch; print(torch.cuda.is_available())"
```

---

# Python Environment Strategy

## Base Environment

Location:

```text
/opt/venv
```

Contains stable tooling:

- Jupyter
- VS Code helpers
- debugging utilities
- data libraries
- infrastructure clients

Examples:

```text
numpy
scipy
pandas
polars
opencv
sklearn
dask
boto3
fastapi
sql clients
```

---

# Project Environments

Create isolated environments per project.

Example:

```bash
cd my-project

uv venv

source .venv/bin/activate
```

Install ML frameworks:

```bash
uv pip install torch transformers
```

Project-specific:

```text
torch
tensorflow
jax
transformers
accelerate
vllm
flash-attn
deepspeed
bitsandbytes
```

---

# VS Code Web

VS Code browser environment included.

Runs:

```text
code serve-web
```

Architecture:

```text
browser
   |
 nginx
   |
 VS Code Web
```

Defaults:

```text
VS Code port : 8887
Public port  : ${SVC_PORT:-8888}
Base path    : ${NB_PREFIX:-/}
```

Features:

- preinstalled extensions
- notebook support
- persistent server cache
- reverse proxy support

Configuration:

```text
NB_PREFIX
SVC_PORT
ENABLE_CONNECT_PROXY
```

---

# Upgrade Policy

Safe updates:

- VS Code version
- Python patch version
- notebook tooling
- CPU utilities

Require new image tag:

- CUDA version changes
- Python minor version changes
- dependency baseline changes

Do not upgrade CUDA manually:

```bash
apt upgrade cuda*
```

CUDA packages are pinned:

```bash
apt-mark hold
```

---

# Design Principle

The container provides:

```text
stable operating environment
            +
developer tooling
            +
CUDA build capability
```

Projects provide:

```text
ML frameworks
experiments
model dependencies
runtime choices
```

The platform stays boring.

The projects are allowed to be chaotic.