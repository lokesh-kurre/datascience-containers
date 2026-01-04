# VS Code on Web

This document describes how this repository prepares and runs VS Code in browser mode (`code serve-web`) using the `dists/vscode-web` image.

## Current pinned version

- Channel: `stable`
- Platform: `linux-x64`
- VS Code version: `1.124.2`
- Commit: `6928394f91b684055b873eecb8bc281365131f1c`

These values are wired in `dists/vscode-web/Dockerfile` through:

- `ARG VSCODE_VERSION=1.124.2`
- `ARG VSCODE_GIT_HASH=6928394f91b684055b873eecb8bc281365131f1c`

## Release metadata endpoints

```bash
curl https://update.code.visualstudio.com/api/releases/<channel>
curl https://update.code.visualstudio.com/api/commits/<channel>/<platform>
curl -L https://update.code.visualstudio.com/api/latest/<platform>/<channel>
```

## Artifacts used by this image

The image downloads and prepares three components:

1. CLI binary (`code`):

```bash
wget -qO cli.tar.gz \
    https://update.code.visualstudio.com/commit:<commit>/cli-linux-x64/stable
```

2. Web server backend for `serve-web`:

```bash
wget -qO web-server.tar.gz \
    https://update.code.visualstudio.com/commit:<commit>/server-linux-x64-web/stable
```

Extracted under:

```text
/opt/vscode-web-server/cli/serve-web/<commit>
```

3. VS Code server package:

```bash
wget -qO server.tar.gz \
    https://update.code.visualstudio.com/commit:<commit>/server-linux-x64/stable
```

Extracted under:

```text
/opt/vscode-server/bin/<commit>
```

## Runtime command

The service launcher (`services.d/vscode-server/run`) starts:

```bash
code serve-web \
    --host 0.0.0.0 \
    --port 8887 \
    --without-connection-token \
    --cli-data-dir /opt/vscode-web-server/cli \
    --server-data-dir /opt/vscode-web-server \
    --server-base-path "${CLEANED_NB_PREFIX}" \
    --disable-telemetry \
    --commit-id ${VSCODE_GIT_HASH} \
    --default-folder ${SERVE_DIR} \
    --socket-path /var/run/shared/vscode.sock
```

Notes:

- `CLEANED_NB_PREFIX` is normalized from `NB_PREFIX` (`/` collapse + trailing slash removed).
- `--server-base-path` is quoted so an empty prefix is passed as an empty string when needed.

## Security and behavior notes

- Dynamic connect proxy endpoint is controlled by `ENABLE_CONNECT_PROXY` in `cont-init.d/01-nginx-config`.
- Default is `ENABLE_CONNECT_PROXY=1` to preserve existing behavior.
- Set `ENABLE_CONNECT_PROXY=0` to disable `${NB_PREFIX}/connect/<ip:port>/<path>` proxying.
- nginx TLS protocols are restricted to `TLSv1.2 TLSv1.3`.
- VS Code user data under `/opt/vscode-web-server/data` is owned by `jovyan:shared` and uses group-writable permissions (`ug+rwX,o-rwx`).

## Preinstalled extensions

Extension IDs are listed in:

```text
dists/vscode-web/vscode-extensions.txt
```

During build they are installed to:

```text
/opt/vscode-web-server/extensions
```

and copied into:

```text
/opt/vscode-server/extensions
```

## Upgrade workflow

1. Pick new `version` and matching `commit`.
2. Update `VSCODE_VERSION` and `VSCODE_GIT_HASH` in `dists/vscode-web/Dockerfile`.
3. Rebuild image and validate `code --version` and browser access.
4. Verify extension install succeeds.
5. Publish image with a new immutable tag.