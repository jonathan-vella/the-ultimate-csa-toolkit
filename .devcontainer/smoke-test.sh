#!/usr/bin/env bash
set -euo pipefail
trap 'printf "Smoke test failed at line %s; adoption is not complete.\n" "$LINENO" >&2' ERR
mode=${1:-full}
case "$mode" in full|--without-browsers) ;; *) echo 'Usage: smoke-test.sh [--without-browsers]' >&2; exit 2 ;; esac
[[ $(id -u) != 0 ]] || { echo 'Run smoke tests as the Dev Container user, not root.' >&2; exit 1; }
source /opt/csa-toolkit/tool-versions.env
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf 'Smoke testing %s as %s\n' "$(uname -m)" "$(id -un)"
sudo -n true
[[ $(lsb_release -rs) == 4.0 ]]
for tool in git wget dot rsvg-convert fc-match pwsh bicep az terraform terragrunt tflint trivy gh uv node npm yarn pnpm markdownlint-cli2 mmdc playwright; do
    command -v "$tool"
done
[[ $(node --version) == "v$NODE_VERSION" ]]
[[ $(python --version) == "Python $PYTHON_VERSION" ]]
source "$NVM_DIR/nvm.sh"
[[ $(nvm current) == "v$NODE_VERSION" ]]
yarn --version
pnpm --version
uv --version
pandoc --version
gh --version
terragrunt --version
trivy --version
mkdir -p "$HOME/.cache/uv" "$HOME/.config/gh"
test -w "$HOME/.cache/uv"
test -w "$HOME/.config/gh"
[[ $(az version --query '"azure-cli"' -o tsv) == "$AZURE_CLI_VERSION" ]]
[[ $(terraform version -json | jq -r .terraform_version) == "$TERRAFORM_VERSION" ]]
bicep --version
az bicep version
printf "output message string = 'acceptance'\n" > "$work/main.bicep"
bicep build "$work/main.bicep" --outfile "$work/standalone.json"
az bicep build --file "$work/main.bicep" --outfile "$work/cli.json"
python - "$work" <<'PY'
import json
import sys
from pathlib import Path
root = Path(sys.argv[1])
assert json.loads((root / "standalone.json").read_text()) == json.loads((root / "cli.json").read_text())
PY
pwsh -NoProfile -Command '$ErrorActionPreference = "Stop"; foreach ($n in @("Az.Accounts","Az.Resources","Az.Storage","Az.Network","Az.KeyVault","Az.Websites")) { Import-Module $n -ErrorAction Stop }; Get-Command New-AzResourceGroupDeployment -ErrorAction Stop; Get-Command bicep -ErrorAction Stop'

printf 'digraph G { Azure -> Toolkit }\n' > "$work/graph.dot"
dot -Tsvg "$work/graph.dot" -o "$work/graph.svg"
dot -Tpng "$work/graph.dot" -o "$work/graph.png"
rsvg-convert "$work/graph.svg" -o "$work/rsvg.png"
fc-match 'Liberation Sans' | grep -F 'Liberation Sans'
printf '# Acceptance\n\n![Graph](graph.png)\n' > "$work/document.md"
pandoc "$work/document.md" --resource-path="$work" --standalone -o "$work/document.html"
pandoc "$work/document.md" --resource-path="$work" -o "$work/document.docx"
python /opt/csa-toolkit/smoke-test.py "$work"

printf '# Acceptance\n\nA clean Markdown fixture.\n' > "$work/lint.md"
(cd "$work" && markdownlint-cli2 lint.md)
printf '# Acceptance\n\n### Skipped heading level\n' > "$work/lint-fail.md"
if (cd "$work" && markdownlint-cli2 lint-fail.md) > "$work/markdownlint.log" 2>&1; then
    echo 'markdownlint failed to reject an invalid fixture.' >&2
    exit 1
fi
grep -q 'MD001' "$work/markdownlint.log"
mkdir "$work/terraform"
printf 'terraform { required_version = ">= 1.0" }\n' > "$work/terraform/main.tf"
terraform -chdir="$work/terraform" init -backend=false
terraform -chdir="$work/terraform" validate
printf 'terraform { source = "../terraform" }\n' > "$work/terragrunt.hcl"
terragrunt hcl validate --working-dir "$work"
mkdir "$work/tflint"
printf 'variable "unused" { type = string }\n' > "$work/tflint/main.tf"
if tflint --chdir="$work/tflint" --enable-rule=terraform_unused_declarations --format=json > "$work/tflint.json"; then
    lint_status=0
else
    lint_status=$?
fi
[[ "$lint_status" == 2 ]]
jq -e '.issues | any(.rule.name == "terraform_unused_declarations")' "$work/tflint.json"
mkdir "$work/trivy"
printf 'FROM alpine:3.22\nUSER root\n' > "$work/trivy/Dockerfile"
trivy config --skip-check-update --format json --output "$work/trivy.json" "$work/trivy"
jq -e '[.Results[].Misconfigurations[]?] | any(.ID == "DS-0002" and .Status == "FAIL")' "$work/trivy.json"

if [[ "$mode" == full ]]; then
    node /opt/csa-toolkit/smoke-browser.cjs "$work"
    printf 'flowchart LR\n  Azure --> Toolkit\n' > "$work/mermaid.mmd"
    mmdc -i "$work/mermaid.mmd" -o "$work/mermaid.svg"
    mmdc -i "$work/mermaid.mmd" -o "$work/mermaid.png"
    grep -q '<svg' "$work/mermaid.svg"
    python - "$work" <<'PY'
import sys
from pathlib import Path
from PIL import Image
for name in ("playwright.png", "puppeteer.png", "mermaid.png"):
    with Image.open(Path(sys.argv[1]) / name) as image:
        assert image.width > 10 and image.height > 10
        image.verify()
PY
    echo 'All automated workflow smoke tests passed; editor/native-architecture acceptance is separate.'
else
    echo 'Non-browser workflow checks passed. PARTIAL validation: browser adoption gates remain open.'
fi
