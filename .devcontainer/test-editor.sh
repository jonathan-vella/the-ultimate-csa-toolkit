#!/usr/bin/env bash
set -euo pipefail
trap 'printf "Editor acceptance failed at line %s.\n" "$LINENO" >&2' ERR

if [[ $# != 0 ]]; then
    echo 'Usage: bash .devcontainer/test-editor.sh (inside the VS Code container terminal)' >&2
    exit 2
fi
if [[ ! -t 0 || -z ${VSCODE_IPC_HOOK_CLI:-} ]]; then
    echo 'Run this interactively in the integrated terminal of VS Code attached to the Dev Container.' >&2
    exit 1
fi
[[ $(id -un) == vscode ]] || { echo 'Run as vscode, not root.' >&2; exit 1; }
case "$(uname -m)" in
    aarch64|x86_64) ;;
    *) echo 'Acceptance requires a native ARM64 or x64 machine.' >&2; exit 1 ;;
esac

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bash /opt/csa-toolkit/smoke-test.sh

confirm() {
    local answer
    printf '\n%s\nType PASS only after verifying this in VS Code: ' "$1"
    read -r answer
    if [[ "$answer" != PASS ]]; then
        echo 'Editor acceptance not confirmed; inspect the relevant Output channel and Dev Containers log.' >&2
        exit 1
    fi
}

printf '\nConfigured extensions (some run locally rather than inside the container):\n'
python - "$root/.devcontainer/devcontainer.json" <<'PY'
import json
import sys
from pathlib import Path
config = json.loads(Path(sys.argv[1]).read_text())
for extension in config["customizations"]["vscode"]["extensions"]:
    print(f"  {extension}")
PY

confirm 'In Extensions, verify every listed extension is installed, enabled for this workspace and on its appropriate local/container host. Check Developer: Show Running Extensions after exercising their features; investigate activation errors in Output and Log (Extension Host). Installation alone is not activation.'
confirm 'Open a Python file: select /opt/csa-toolkit/.venv/bin/python, confirm completion and Run Python File work. Open Bicep: confirm completion/diagnostics. Start a PowerShell integrated session and import Az.Accounts. Open Terraform and confirm syntax/language features work without deployment.'
confirm 'Open Markdown with a Mermaid diagram: verify preview rendering, markdownlint diagnostics and formatting on save. Exercise YAML validation, CSV highlighting, Git Graph, Git History and the resource monitor.'
confirm 'Open Azure Resources, GitHub Actions and Pull Requests views: confirm their commands/views activate without extension-host errors. Authentication or service data may be unavailable; do not deploy or sign in just for this test. Exercise the Azure CLI extension and Azure MCP extension commands as well.'
confirm 'In the MCP server list, verify Microsoft Learn starts/connects and its tools are available. Inspect the MCP Output channel for failures. Verify the terminal uses Bash and the expected Python interpreter remains selected.'
confirm 'Confirm this machine is native ARM64 or x64, not an emulated container. Verify workspace edits are writable and retained, and the uv/GitHub cache mounts are writable after reopening the container. Do not inspect or share Azure credential files.'

printf '\nAutomated workflows and manually confirmed editor checks passed on %s.\n' "$(uname -m)"
printf 'This result covers this native machine only; repeat on the other architecture.\n'
