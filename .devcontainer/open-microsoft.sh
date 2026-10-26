#!/usr/bin/env bash
set -euo pipefail

if ! command -v code >/dev/null 2>&1; then
    printf 'VS Code CLI is required; enable the code command on your host PATH first.\n' >&2
    exit 127
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export CSA_NPM_REGISTRY_HOST_PATH=packagefeedproxy.microsoft.io/npm/
export CSA_PYPI_INDEX_HOST_PATH=packagefeedproxy.microsoft.io/pypi/simple/
export CSA_POWERSHELL_REPOSITORY_URL=https://packagefeedproxy.microsoft.io/powershell/v2

if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    IFS=: read -r -a entries <<< "${WSLENV:-}"
    forwarded=""
    for entry in "${entries[@]}"; do
        case "${entry%%/*}" in
            CSA_NPM_REGISTRY_HOST_PATH | CSA_PYPI_INDEX_HOST_PATH | CSA_POWERSHELL_REPOSITORY_URL | "") ;;
            *) forwarded="${forwarded}${entry}:" ;;
        esac
    done
    export WSLENV="${forwarded}CSA_NPM_REGISTRY_HOST_PATH:CSA_PYPI_INDEX_HOST_PATH:CSA_POWERSHELL_REPOSITORY_URL"
fi

printf 'Fully exit all VS Code windows first; an existing process retains its previous environment.\n'
printf 'Opening the toolkit with Microsoft CFS sources for image builds and container setup.\n'
exec code "${SCRIPT_DIR}/.."
