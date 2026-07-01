# VS Code on Web

This document describes how this repository prepares and runs VS Code in browser mode (`code serve-web`) using the `dists/vscode-web` image.

## Current pinned version

- Channel: `stable`
- Platform: `linux-x64`
- VS Code version: configured via `VSCODE_VERSION`
- Commit: derived automatically from installed `code` CLI

The image is wired through:

- `ARG VSCODE_VERSION`

No `VSCODE_GIT_HASH` build arg is required.

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
    https://update.code.visualstudio.com/<version>/cli-linux-x64/stable
```

Then commit is parsed from CLI output, for example:

```bash
code --version
# code 1.125.1 (commit fcf604774b9f2674b473065736ee75077e256353)
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
    --default-folder ${SERVE_DIRECTORY} \
    --socket-path /var/run/shared/vscode.sock
```

`VSCODE_GIT_HASH` is read at runtime from `/opt/vscode-data/VSCODE_GIT_HASH`.

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

1. Pick new `version`.
2. Update `VSCODE_VERSION` in `build_arg.properties` (or pass `--build-arg VSCODE_VERSION=...`).
3. Rebuild image and validate `code --version` and browser access.
4. Verify extension install succeeds.
5. Publish image with a new immutable tag.