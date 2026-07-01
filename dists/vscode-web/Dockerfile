ARG BUILD_TYPE

ARG UBUNTU_VERSION
ARG PYTHON_VERSION
ARG VSCODE_VERSION
ARG VSCODE_GIT_HASH
ARG S6_OVERLAY_VERSION

ARG GIT_REPO
ARG GIT_COMMIT
ARG BUILD_DATE
ARG VERSION

ARG CUDA_MAJOR
ARG CUDA_MINOR

# =============================================================================================================
FROM ubuntu:${UBUNTU_VERSION} AS base

ARG UBUNTU_VERSION

LABEL org.opencontainers.image.title="AIML Golden Notebook Image"
LABEL org.opencontainers.image.vendor="AIML Platform"
LABEL org.opencontainers.image.base.os="ubuntu:${UBUNTU_VERSION}"
LABEL ai.platform.type="notebook"
LABEL ai.platform.type="vscode"
LABEL ai.platform.cuda.enabled="false"

ARG DEBIAN_FRONTEND
ARG S6_OVERLAY_VERSION

ENV TERM=xterm-256color
ENV SHELL=/bin/bash

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    echo "path-exclude=/usr/share/man/*" > /etc/dpkg/dpkg.cfg.d/01_nodoc \
    && apt-get update && apt-get install -y --no-install-recommends \
    sudo ca-certificates openssl openssh-client curl wget git git-lfs \
    vim nano tmux bash bash-completion gnupg gpg locales lsb-release tzdata \
    tini telnet traceroute net-tools iputils-ping procps dnsutils lsof strace \
    binutils tree jq less rsync sed xxd zip unzip tar gzip bzip2 xz-utils p7zip-full \
    make cmake pkg-config fuse nodejs python3-dev docker-cli gettext nginx s3fs \
    termtris ttyd ripgrep file acl psmisc socat apt-utils apt-transport-https \
    iproute2 iptables nftables nmap tcpdump whois netcat-openbsd mtr-tiny \
    unrar perl inotify-tools mold clang llvm lld htop nvtop numactl linux-tools-common linux-tools-generic graphviz  \
    libgraphviz-dev libhdf5-dev libsndfile1 libsox-dev sox libopenmpi-dev openmpi-bin \
    libgl1 libglib2.0-0 libgomp1 libquadmath0 libstdc++6 libgcc-s1 libopenblas0 liblapack3 libjpeg-turbo8 libpng16-16 \
    ffmpeg libsm6 libxext6 libxrender1 libfontconfig1 libfreetype6 libffi8 libssl3 \
    autotools-dev gdb libc6-dbg gfortran libboost-all-dev libeigen3-dev \
    libicu-dev libbz2-dev zlib1g-dev pciutils libffi-dev libssl-dev \
    build-essential gcc g++ make cmake ninja-build pkg-config python3-dev \
    libncurses-dev libreadline-dev libsqlite3-dev liblzma-dev ccache patchelf

ENV TZ=Asia/Kolkata
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone

RUN git lfs install

RUN curl -L https://dl.k8s.io/release/v1.36.1/bin/linux/amd64/kubectl \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl \
    && update-alternatives --install /usr/local/bin/k k /usr/local/bin/kubectl 1 \
    && wget https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64 -O /usr/local/bin/confd && chmod +x /usr/local/bin/confd

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN sudo tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN sudo tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

ENTRYPOINT [ "/usr/bin/tini", "--" ]

CMD [ "/bin/bash" ]

# =============================================================================================================
FROM base AS cuda-builder

ARG CUDA_MAJOR
ARG CUDA_MINOR
ARG CUDA_VERSION=${CUDA_MAJOR}.${CUDA_MINOR}
ARG CUDA_PKG_VERSION=${CUDA_MAJOR}-${CUDA_MINOR}

USER root

RUN wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb \
    -O /tmp/cuda-keyring.deb \
    && dpkg -i /tmp/cuda-keyring.deb \
    && rm /tmp/cuda-keyring.deb

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    CUDA_PACKAGES="\
    cuda-minimal-build-${CUDA_PKG_VERSION} \
    cuda-cudart-dev-${CUDA_PKG_VERSION} \
    cuda-nvrtc-dev-${CUDA_PKG_VERSION} \
    cuda-nvml-dev-${CUDA_PKG_VERSION} \
    libcublas-dev-${CUDA_PKG_VERSION} \
    libcusparse-dev-${CUDA_PKG_VERSION} \
    libcurand-dev-${CUDA_PKG_VERSION} \
    libcusolver-dev-${CUDA_PKG_VERSION}" \
    && apt-get update \
    && apt-get install -y --no-install-recommends ${CUDA_PACKAGES} \
    && apt-mark hold ${CUDA_PACKAGES}

# =============================================================================================================
FROM base AS base-python

ARG PYTHON_VERSION

LABEL org.opencontainers.image.python.version=${PYTHON_VERSION}

RUN groupadd shared \
    && useradd -m -d /home/jovyan -u 1000 -g shared -G root --shell /bin/bash jovyan \
    && usermod -aG shared jovyan \
    && echo "jovyan ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jovyan \
    && chmod 0440 /etc/sudoers.d/jovyan

ENV XDG_DATA_HOME=/opt/share

# Fixing permissions for shared volumes and directories
RUN install -g shared -m 2775 -d /var/run/shared /opt /opt/share \
    && setfacl -m d:g:shared:rwx /opt /var/run/shared

RUN curl -Ls https://astral.sh/uv/install.sh |  \
    UV_INSTALL_DIR=/usr/local/bin bash

ENV PATH=/opt/bin:$PATH
RUN for v in $(seq 8 14); do \
    uv python install "3.${v}" || true; \
    done

USER jovyan

ENV VIRTUAL_ENV_DISABLE_PROMPT=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    TF_CPP_MIN_LOG_LEVEL=2

RUN --mount=type=cache,target=/tmp/uv-cache-jovyan,uid=1000,gid=1000 \
    DEPS="opencv-python-headless==0 opencv-contrib-python==0 opencv-python==0" \
    && VIRTUAL_ENV=/opt/venv uv venv /opt/venv --python "${PYTHON_VERSION}" \
    && touch /opt/venv/pinned \
    && printf '%s\n' ${DEPS} >> /opt/venv/pinned \
    && chmod 0644 /opt/venv/pinned \
    && UV_CACHE_DIR=/tmp/uv-cache-jovyan UV_CONSTRAINT=/opt/venv/pinned VIRTUAL_ENV=/opt/venv uv pip install \
    pip \
    isort \
    ipykernel

CMD [ "/bin/bash", "--login" ]

# =============================================================================================================
FROM base-python AS base-python-codeserver-jupyter

ARG VSCODE_VERSION
ARG VSCODE_GIT_HASH

ENV VSCODE_VERSION=${VSCODE_VERSION}
ENV VSCODE_GIT_HASH=${VSCODE_GIT_HASH}

RUN install -d /opt/vscode-data/ /opt/vscode-server/ \
    && wget -qO /opt/vscode-data/cli_${VSCODE_VERSION}.tar.gz https://update.code.visualstudio.com/commit:${VSCODE_GIT_HASH}/cli-linux-x64/stable \
    && tar -xzf /opt/vscode-data/cli_${VSCODE_VERSION}.tar.gz -C /tmp \
    && sudo install -m 0755 -o root -g root /tmp/code /usr/bin/code \
    && rm /tmp/code

RUN install -d /opt/vscode-data/ /opt/vscode-web-server/cli/serve-web \
    && wget -qO /opt/vscode-data/web_server_${VSCODE_GIT_HASH}.tar.gz https://update.code.visualstudio.com/commit:${VSCODE_GIT_HASH}/server-linux-x64-web/stable \
    && tar -xzf /opt/vscode-data/web_server_${VSCODE_GIT_HASH}.tar.gz -C /opt/vscode-web-server/cli/serve-web/ \
    && mv /opt/vscode-web-server/cli/serve-web/vscode-server-linux-x64-web /opt/vscode-web-server/cli/serve-web/${VSCODE_GIT_HASH}

RUN install -d /opt/vscode-server/bin \
    && wget -qO /opt/vscode-data/server_${VSCODE_GIT_HASH}.tar.gz https://update.code.visualstudio.com/commit:${VSCODE_GIT_HASH}/server-linux-x64/stable \
    && tar -xzf /opt/vscode-data/server_${VSCODE_GIT_HASH}.tar.gz -C /opt/vscode-server/bin/ \
    && mv /opt/vscode-server/bin/vscode-server-linux-x64 /opt/vscode-server/bin/${VSCODE_GIT_HASH} \
    && chmod -R a+rwX /opt/vscode-server/ \
    && tar -czf /opt/vscode-data/server_${VSCODE_GIT_HASH}.tar.gz -C /opt/vscode-server/ /opt/vscode-server/bin/${VSCODE_GIT_HASH} \
    && code version use --install-dir /opt/vscode-server/bin/${VSCODE_GIT_HASH}/bin/code-server stable \
    && sudo ln -sf /opt/vscode-server/ /root/.vscode-server

COPY dists/vscode-web/vscode-extensions.txt /opt/vscode-data/extensions.list
RUN xargs -a /opt/vscode-data/extensions.list -I {} sh -c 'code --install-extension {} --extensions-dir /opt/vscode-web-server/extensions/ || true' \
    && cp -r /opt/vscode-web-server/extensions/ /opt/vscode-server/extensions/ \
    && tar -czf /opt/vscode-data/vscode-server-with-extensions.tar.gz -C /opt/vscode-server/ /opt/vscode-server/

RUN --mount=type=cache,target=/tmp/uv-cache-jovyan,uid=1000,gid=1000  \
    DEPS="setuptools[core]<81.0.0 build wheel pip" \
    && UV_CACHE_DIR=/tmp/uv-cache-jovyan VIRTUAL_ENV=/opt/venv uv pip install ${DEPS} \
    && printf '%s\n' ${DEPS} >> /opt/venv/pinned

COPY dists/vscode-web/notebook-extensions.txt /opt/notebook-data/extensions.list
RUN --mount=type=cache,target=/tmp/uv-cache-jovyan,uid=1000,gid=1000  \
    DEPS="notebook==6.5.7" \
    && UV_CACHE_DIR=/tmp/uv-cache-jovyan UV_CONSTRAINT=/opt/venv/pinned VIRTUAL_ENV=/opt/venv \
    uv pip install --no-build-isolation \
    ${DEPS} ipywidgets widgetsnbextension jupyter_contrib_nbextensions  \
    git+https://github.com/Jupyter-contrib/jupyter_contrib_core/@master \
    && VIRTUAL_ENV=/opt/venv uv run jupyter nbextension install --py jupyter_nbextensions_configurator --sys-prefix \
    && VIRTUAL_ENV=/opt/venv uv run jupyter contrib nbextension install --sys-prefix \
    && xargs -a /opt/notebook-data/extensions.list -I {} sh -c 'VIRTUAL_ENV=/opt/venv uv run jupyter nbextension enable {} --sys-prefix || true' \
    && printf '%s\n' ${DEPS} >> /opt/venv/pinned

# =============================================================================================================
FROM base-python-codeserver-jupyter AS base-python-codeserver-jupyter-cpu

USER root

COPY rootfs/ /

RUN --mount=type=cache,target=/tmp/uv-cache-root echo "-c /opt/requirements/00-constraints.txt" >> /opt/venv/pinned \
    && UV_CACHE_DIR=/tmp/uv-cache-root UV_CONSTRAINT=/opt/venv/pinned VIRTUAL_ENV=/opt/venv uv pip install --no-build-isolation \
    -r /opt/requirements/00-general-requirements.txt -r /opt/requirements/01-cpu-requirements.txt

RUN rm -rf /root/.cache

RUN find /etc/cont-init.d/ /etc/services.d/ -type f -exec chmod +x {} +

ENTRYPOINT ["/init"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -fsSL "http://127.0.0.1:${SERVICE_PORT:-8888}/health" || exit 1


# =============================================================================================================
FROM base-python-codeserver-jupyter-cpu AS base-python-codeserver-jupyter-gpu

ARG CUDA_MAJOR
ARG CUDA_MINOR
ARG CUDA_VERSION=${CUDA_MAJOR}.${CUDA_MINOR}

COPY --from=cuda-builder /usr/local/cuda-${CUDA_VERSION} /usr/local/cuda-${CUDA_VERSION}

RUN ln -sfn /usr/local/cuda-${CUDA_VERSION} /usr/local/cuda && \
    ln -sfn /usr/local/cuda-${CUDA_VERSION} /usr/local/cuda-${CUDA_MAJOR}

ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV CUDAToolkit_ROOT=/usr/local/cuda

ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${CUDA_HOME}/targets/x86_64-linux/lib/stubs
ENV LIBRARY_PATH=${CUDA_HOME}/targets/x86_64-linux/lib/stubs:${LIBRARY_PATH}

RUN nvcc --version && \
    printf "%s\n" \
    "#include <cuda.h>" \
    "#include <cuda_runtime.h>" \
    "#include <cublas_v2.h>" \
    "#include <cusolverDn.h>" \
    "#include <cusparse.h>" \
    "#include <curand.h>" \
    "#include <nvrtc.h>" \
    "int main() { return 0; }" \
    > /tmp/test_compilation.cu \
    && nvcc -x cu /tmp/test_compilation.cu -c -o /tmp/test_compilation.o \
    -lcublas -lcusolver -lcusparse -lcurand -lnvrtc \
    && rm /tmp/test_compilation.cu /tmp/test_compilation.o

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

LABEL ai.platform.cuda.enabled="true" \
    ai.platform.cuda.version="${CUDA_VERSION}" \
    ai.platform.cuda.mode="compile-only" \
    ai.platform.cuda.components="nvcc,headers,nvrtc,nvml"

# =============================================================================================================
FROM base-python-codeserver-jupyter-${BUILD_TYPE} AS final

ARG GIT_REPO
ARG GIT_COMMIT
ARG BUILD_DATE
ARG VERSION
ARG BUILD_TYPE

LABEL org.opencontainers.image.source="${GIT_REPO}" \
    org.opencontainers.image.revision="${GIT_COMMIT}" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.version="${VERSION}" \
    ai.platform.variant="${BUILD_TYPE}" 