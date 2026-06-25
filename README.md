# Data Science Containers

Reusable production-grade container images for AI/ML development environments.

This repository builds opinionated **base workspace images** containing:

- Ubuntu
- Python (`uv` managed)
- VS Code Web
- Jupyter Notebook
- developer utilities
- scientific Python foundation
- optional CUDA development support

The goal is to provide a stable engineering platform while keeping ML frameworks and project dependencies isolated.

---

# Philosophy

The container provides the foundation:

```text
Operating System
        |
Development Toolchain
        |
Python Runtime
        |
VS Code + Notebook
        |
CUDA Build Capability (optional)
```

Projects provide:

```text
PyTorch
TensorFlow
JAX
Transformers
Application dependencies
Experiment packages
```

The image intentionally avoids becoming a huge framework bundle.

Different projects can use different ML stacks without rebuilding the base image.

---

# Images

Published repository:

```text
lokeshkurre/vscode-web
```

## CPU

```text
lokeshkurre/vscode-web:ubuntu22.04-py3.11-vscode1.125.1-cpu
```

## CUDA

```text
lokeshkurre/vscode-web:ubuntu22.04-py3.11-vscode1.125.1-cuda12.2
```

---

# Tag Format

```text
ubuntu<version>-py<version>-vscode<version>-<variant>
```

Examples:

```text
ubuntu22.04-py3.11-vscode1.125.1-cpu

ubuntu22.04-py3.11-vscode1.125.1-cuda12.2
```

Tags are immutable.

The project does not publish `latest`.

---

# Repository Architecture

Build graph:

```text
                 ubuntu
                    |
                  base
                    |
        +-----------+-----------+
        |                       |
 CUDA builder              Python layer
        |                       |
        |                    uv runtime
        |                       |
        |                VS Code + Jupyter
        |                       |
        |                    CPU image
        |                       |
        +------------------> GPU image
```

Benefits:

- CPU/GPU share maximum layers
- CUDA installation is isolated
- Python dependency changes do not reinstall CUDA
- faster rebuilds
- reproducible images

---

# CUDA Design

The CUDA image is a development image.

It provides:

- nvcc compiler
- CUDA headers
- CUDA runtime development files
- NVRTC
- NVML development files
- cuBLAS development files
- cuSPARSE development files
- cuRAND development files
- cuSOLVER development files

Used for:

- PyTorch extensions
- CUDA custom operators
- Triton kernels
- native CUDA builds

Example workloads:

```text
flash-attn compilation
custom torch operators
CUDA/C++ extensions
TensorRT plugins
```

---

# CUDA Runtime Strategy

CUDA frameworks are installed by projects.

Example:

```bash
uv pip install torch
```

Framework packages manage:

- CUDA runtime libraries
- cuDNN
- NCCL
- framework-specific dependencies

The base image only provides the compiler/toolchain.

---

# Build

Enable BuildKit:

```bash
export DOCKER_BUILDKIT=1
```

## CPU

```bash
docker build \
  --build-arg BUILD_TYPE=cpu \
  -t vscode-web:cpu .
```

## GPU

```bash
docker build \
  --build-arg BUILD_TYPE=gpu \
  -t vscode-web:cuda12.2 .
```

---

# Build Arguments

Available arguments:

| Argument | Description |
|-|-|
| UBUNTU_VERSION | Ubuntu base version |
| PYTHON_VERSION | default Python version |
| VSCODE_VERSION | VS Code version |
| VSCODE_GIT_HASH | VS Code build commit |
| CUDA_MAJOR | CUDA major version |
| CUDA_MINOR | CUDA minor version |
| BUILD_TYPE | cpu/gpu |

Example:

```bash
docker build \
  --build-arg PYTHON_VERSION=3.11.13 \
  --build-arg CUDA_MAJOR=12 \
  --build-arg CUDA_MINOR=2 \
  --build-arg BUILD_TYPE=gpu \
  .
```

---

# Runtime User Model

Containers run services as:

```text
user: jovyan
uid : 1000
```

Services:

- VS Code
- Jupyter
- terminals

run without root privileges.

The init system performs setup and then drops privileges.

---

# Shared Storage Support

Designed for:

- NFS
- shared workstation mounts
- Kubernetes volumes
- enterprise storage

Linux permissions use numeric IDs.

Matching usernames on the storage server are not required.

---

# Supplementary Groups

Additional runtime groups are supported.

Example:

```bash
docker run \
  --group-add 5000 \
  -v /data/project:/workspace \
  vscode-web:cpu
```

The group is available inside:

```text
VS Code
Jupyter
terminal
child processes
```

---

# Primary Group Override

Some shared filesystems require the process primary group to match the directory group.

Set:

```text
PRIMARY_GID
```

Example:

```bash
docker run \
  -e PRIMARY_GID=5000 \
  --group-add 5000 \
  -v /shared/project:/workspace \
  vscode-web:cpu
```

The service user becomes:

```text
uid=1000(jovyan)
gid=5000
```

New files are created using that group.

---

# Recommended Shared Directory Setup

On shared storage:

```bash
chmod g+s /shared/project

setfacl -d -m g::rwx /shared/project
```

New files inherit group permissions.

---

# Python Environment

Base environment:

```text
/opt/venv
```

Contains:

- notebook tooling
- VS Code integration
- debugging utilities
- common scientific packages

Application dependencies should not be installed here.

---

# Project Workflow

Create isolated environments:

```bash
cd project

uv venv

source .venv/bin/activate
```

Install dependencies:

```bash
uv pip install torch transformers
```

Each project controls its own stack.

---

# Services

The image includes:

## VS Code Web

Browser-based IDE.

Features:

- extensions
- notebooks
- terminals
- development workflow

## Jupyter Notebook

Integrated notebook environment.

---

# Runtime Environment Variables

| Variable | Purpose |
|-|-|
| SERVICE_PORT | service port |
| NB_PREFIX | URL prefix |
| ENABLE_CONNECT_PROXY | proxy support |
| PRIMARY_UID | override service primary userid |
| PRIMARY_GID | override service primary groupid |

---

# Metadata

Images include OCI labels:

```text
org.opencontainers.image.source
org.opencontainers.image.revision
org.opencontainers.image.created
org.opencontainers.image.version
```

---

# Design Goals

- reproducible builds
- small rebuild surface
- shared CPU/GPU layers
- enterprise filesystem compatibility
- no framework lock-in
- project-level dependency isolation

A stable platform for unstable ML ecosystems.