#!/usr/bin/env bash
set -euo pipefail
trap 'printf "Dev Container initialization failed at line %s\n" "$LINENO" >&2' ERR

mkdir -p "$HOME/.cache/uv" "$HOME/.config/gh"
# These two named volumes can retain an earlier container UID; never change the host Azure bind mount.
sudo chown -R "$(id -u):$(id -g)" "$HOME/.cache/uv" "$HOME/.config/gh"
git config --global --replace-all safe.directory "$PWD"
git config --global core.autocrlf input

if [[ -f package.json ]]; then
    if [[ -f package-lock.json ]]; then
        npm ci
    else
        npm install
    fi
fi
if [[ -f requirements.txt ]]; then
    uv venv --python "$(command -v python)" .venv
    uv pip install --python .venv/bin/python -r requirements.txt
    printf 'Workspace requirements installed in %s/.venv; select it for workspace scripts.\n' "$PWD"
fi
bash /opt/csa-toolkit/smoke-test.sh
