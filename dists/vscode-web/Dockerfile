ARG BUILD_TYPE=cpu
ARG UBUNTU_VERSION=22.04
ARG PYTHON_VERSION=3.10.13
ARG BUILD_MODE=base # base, dev
ARG VSCODE_VERSION=1.124.2
ARG VSCODE_GIT_HASH=6928394f91b684055b873eecb8bc281365131f1c
ARG S6_OVERLAY_VERSION=3.2.3.0

ARG CUDA_VERSION=12.2.2
ARG CUDNN_VERSION=8
ARG CUDA_FLAVOR=devel

# =============================================================================================================
FROM ubuntu:${UBUNTU_VERSION} AS base-cpu

ARG UBUNTU_VERSION

LABEL org.opencontainers.image.title="AIML Golden Notebook Image"
LABEL org.opencontainers.image.vendor="AIML Platform"
LABEL org.opencontainers.image.base.os="ubuntu:${UBUNTU_VERSION}"
LABEL ai.platform.type="notebook"
LABEL ai.platform.type="vscode"
LABEL ai.platform.cuda="false"

RUN ln -sf /bin/bash /entrypoint.sh

# =============================================================================================================
FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-${CUDA_FLAVOR}-ubuntu${UBUNTU_VERSION} AS base-gpu

ARG CUDA_VERSION
ARG CUDNN_VERSION

LABEL org.opencontainers.image.title="AIML Golden Notebook Image"
LABEL org.opencontainers.image.vendor="AIML Platform"
LABEL org.opencontainers.image.cuda.version=${CUDA_VERSION}
LABEL org.opencontainers.image.cudnn.version=${CUDNN_VERSION}
LABEL org.opencontainers.image.base.os="ubuntu:${UBUNTU_VERSION}"
LABEL ai.platform.type="notebook"
LABEL ai.platform.type="vscode"
LABEL ai.platform.cuda="true"

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

RUN ln -fs /opt/nvidia/nvidia_entrypoint.sh /entrypoint.sh

# =============================================================================================================
FROM base-${BUILD_TYPE} AS base

ARG DEBIAN_FRONTEND=noninteractive
ARG S6_OVERLAY_VERSION

ENV TERM=xterm-256color
ENV SHELL=/bin/bash

RUN echo "path-exclude=/usr/share/man/*" > /etc/dpkg/dpkg.cfg.d/01_nodoc \
    && apt-get update && apt-get install -y --no-install-recommends \
    sudo ca-certificates openssl openssh-client curl wget git git-lfs \
    vim nano tmux bash bash-completion gnupg gpg locales lsb-release tzdata \
    tini telnet traceroute net-tools iputils-ping procps dnsutils lsof strace \
    binutils tree jq less rsync sed xxd zip unzip tar gzip bzip2 xz-utils p7zip-full \
    make cmake pkg-config fuse nodejs python3-dev docker-cli gettext nginx s3fs \
    termtris ttyd ripgrep file acl psmisc socat apt-utils apt-transport-https \
    iproute2 iptables nftables nmap tcpdump whois netcat-openbsd mtr-tiny \
    unrar perl inotify-tools \
    && rm -rf /var/lib/apt/lists/*

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

ENTRYPOINT [ "/usr/bin/tini", "--", "/entrypoint.sh" ]

CMD [ "/bin/bash" ]

# =============================================================================================================
FROM base AS base-python-base

ARG PYTHON_VERSION

LABEL org.opencontainers.image.python.version=${PYTHON_VERSION}

RUN groupadd shared \
    && useradd -m -u 1000 -g shared -G root --shell /bin/bash jovyan \
    && usermod -aG shared jovyan \
    && echo "jovyan ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jovyan \
    && chmod 0440 /etc/sudoers.d/jovyan

ENV XDG_DATA_HOME=/opt/share
ENV TORCH_EXTENSIONS_DIR=/opt/torch_extensions

# Fixing permissions for shared volumes and directories
RUN install -g shared -m 2775 -d /var/run/shared /opt /opt/share /opt/torch_extensions \
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
    PATH="/opt/venv/bin:$PATH" \
    PIP_CONSTRAINT=/opt/venv/pinned \
    UV_CONSTRAINT=/opt/venv/pinned \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    CUDA_LAUNCH_BLOCKING=1 \
    TF_CPP_MIN_LOG_LEVEL=2 \
    OMP_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    NUMEXPR_NUM_THREADS=1 \
    PIP_USER=1

RUN DEPS="opencv-python-headless==0 opencv-contrib-python==0 opencv-python==0" \
    && VIRTUAL_ENV=/opt/venv uv venv /opt/venv --python "${PYTHON_VERSION}" \
    && touch /opt/venv/pinned \
    && printf '%s\n' ${DEPS} >> /opt/venv/pinned \
    && chmod 0644 /opt/venv/pinned \
    && VIRTUAL_ENV=/opt/venv uv pip install \
    pip \
    isort \
    ipykernel \
    && echo 'command -v uv >/dev/null 2>&1 && eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc \
    && echo '[ -z "${VIRTUAL_ENV:-}" ] && [ -f /opt/venv/bin/activate ] && source /opt/venv/bin/activate' >> ~/.bashrc

CMD [ "/bin/bash", "--login" ]

# =============================================================================================================
FROM base-python-base AS base-python-dev

ARG DEBIAN_FRONTEND=noninteractive

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    autotools-dev gdb libc6-dbg gfortran libboost-all-dev libeigen3-dev \
    libicu-dev libbz2-dev zlib1g-dev pciutils libffi-dev libssl-dev \
    build-essential gcc g++ make cmake ninja-build pkg-config python3-dev \
    libncurses-dev libreadline-dev libsqlite3-dev liblzma-dev ccache patchelf \
    && rm -rf /var/lib/apt/lists/*

USER jovyan

# =============================================================================================================
FROM base-python-${BUILD_MODE} AS base-python-codeserver-jupyter

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
    && ln -sf /opt/vscode-server/ /home/jovyan/.vscode-server \
    && sudo ln -sf /opt/vscode-server/ /root/.vscode-server

COPY dists/vscode-web/vscode-extensions.txt /opt/vscode-data/extensions.list
RUN xargs -a /opt/vscode-data/extensions.list -I {} sh -c 'code --install-extension {} --extensions-dir /opt/vscode-web-server/extensions/ || true' \
    && cp -r /opt/vscode-web-server/extensions/ /opt/vscode-server/extensions/ \
    && tar -czf /opt/vscode-data/vscode-server-with-extensions.tar.gz -C /opt/vscode-server/ /opt/vscode-server/

RUN DEPS="setuptools[core]<81.0.0 build wheel pip" \
    && VIRTUAL_ENV=/opt/venv uv pip install ${DEPS} \
    && printf '%s\n' ${DEPS} >> /opt/venv/pinned

COPY dists/vscode-web/notebook-extensions.txt /opt/notebook-data/extensions.list
RUN DEPS="notebook==6.5.7" \
    && VIRTUAL_ENV=/opt/venv \
    uv pip install --no-build-isolation \
    ${DEPS} ipywidgets widgetsnbextension jupyter_contrib_nbextensions  \
    git+https://github.com/Jupyter-contrib/jupyter_contrib_core/@master \
    && uv run jupyter nbextension install --py jupyter_nbextensions_configurator --sys-prefix \
    && uv run jupyter contrib nbextension install --sys-prefix \
    && xargs -a /opt/notebook-data/extensions.list -I {} sh -c 'uv run jupyter nbextension enable {} --sys-prefix || true' \
    && printf '%s\n' ${DEPS} >> /opt/venv/pinned \
    && uv cache clean
    
USER root
    
COPY rootfs/ /

RUN --mount=type=cache,target=/root/.cache/uv echo "-c /opt/requirements/00-constraints.txt" >> /opt/venv/pinned \
&& VIRTUAL_ENV=/opt/venv uv pip install --no-build-isolation \
-r /opt/requirements/00-general-requirements.txt -r /opt/requirements/01-cpu-requirements.txt

RUN find /etc/cont-init.d/ /etc/services.d/ -type f -exec chmod +x {} +

ENTRYPOINT ["/init"]

FROM base-python-codeserver-jupyter AS final

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 libgomp1 libquadmath0 libstdc++6 libgcc-s1 libopenblas0 liblapack3 libjpeg-turbo8 libpng16-16 \
    ffmpeg libsm6 libxext6 libxrender1 libfontconfig1 libfreetype6 libffi8 libssl3  \
    && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -fsSL "http://127.0.0.1:${SVC_PORT:-8888}/health" || exit 1