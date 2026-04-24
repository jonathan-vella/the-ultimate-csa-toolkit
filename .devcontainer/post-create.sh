#!/bin/bash
set -e

# ─── Platform Detection ──────────────────────────────────────────────────────

ARCH=$(uname -m)
OS=$(uname -s)
case "$ARCH" in
    x86_64)  ARCH_LABEL="amd64" ;;
    aarch64) ARCH_LABEL="arm64" ;;
    arm64)   ARCH_LABEL="arm64" ;;
    *)       ARCH_LABEL="$ARCH" ;;
esac

# ─── Progress Tracking Helpers ───────────────────────────────────────────────

TOTAL_STEPS=11
CURRENT_STEP=0
SETUP_START=$(date +%s)
STEP_START=0
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

step_start() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    STEP_START=$(date +%s)
    printf "\n [%d/%d] %s %s\n" "$CURRENT_STEP" "$TOTAL_STEPS" "$1" "$2"
}

step_done() {
    local elapsed=$(( $(date +%s) - STEP_START ))
    [[ $elapsed -lt 0 ]] && elapsed=0
    PASS_COUNT=$((PASS_COUNT + 1))
    printf "        ✅ %s (%ds)\n" "${1:-Done}" "$elapsed"
}

step_warn() {
    local elapsed=$(( $(date +%s) - STEP_START ))
    [[ $elapsed -lt 0 ]] && elapsed=0
    WARN_COUNT=$((WARN_COUNT + 1))
    printf "        ⚠️  %s (%ds)\n" "${1:-Completed with warnings}" "$elapsed"
}

step_fail() {
    local elapsed=$(( $(date +%s) - STEP_START ))
    [[ $elapsed -lt 0 ]] && elapsed=0
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf "        ❌ %s (%ds)\n" "${1:-Failed}" "$elapsed"
}

# ─── Banner ──────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 🚀 The Ultimate CSA Toolkit — Dev Container Setup"
echo "    $TOTAL_STEPS steps · $(date '+%H:%M:%S') · $OS/$ARCH ($ARCH_LABEL)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Log output to file for debugging
exec 1> >(tee -a ~/.devcontainer-install.log)
exec 2>&1

# ─── Step 1: npm install (local) ─────────────────────────────────────────────

step_start "📦" "Installing npm dependencies..."
if [ -f "package.json" ]; then
    if npm install --loglevel=warn 2>&1 | tail -3; then
        step_done "npm packages installed"
    else
        step_warn "npm install had issues, continuing"
    fi
else
    step_done "Skipped (no package.json)"
fi

# ─── Step 2: npm global tools ────────────────────────────────────────────────

step_start "📦" "Installing global tools (markdownlint-cli2, @mermaid-js/mermaid-cli, playwright)..."
if sudo npm install -g markdownlint-cli2 @mermaid-js/mermaid-cli playwright --loglevel=warn 2>&1 | tail -2; then
    step_done "Global tools installed"
else
    step_warn "Global install had issues"
fi

step_start "🎭" "Installing Playwright Chromium browser..."
if playwright install chromium --with-deps 2>&1 | tail -2; then
    step_done "Playwright Chromium installed"
else
    step_warn "Playwright Chromium installation had issues"
fi

# ─── Step 3: Directories & Git ───────────────────────────────────────────────

step_start "🔐" "Configuring Git & directories..."
mkdir -p "${HOME}/.cache" "${HOME}/.config/gh"
sudo chown -R vscode:vscode "${HOME}/.cache" 2>/dev/null || true
sudo chown -R vscode:vscode "${HOME}/.config/gh" 2>/dev/null || true
chmod 755 "${HOME}/.cache" 2>/dev/null || true
chmod 755 "${HOME}/.config/gh" 2>/dev/null || true
git config --global --add safe.directory "${PWD}"
git config --global core.autocrlf input
step_done "Git configured, cache dirs created"

# ─── Step 4: Python packages ─────────────────────────────────────────────────

step_start "🐍" "Installing Python packages..."
export PATH="${HOME}/.local/bin:${PATH}"

if command -v uv &> /dev/null; then
    mkdir -p "${HOME}/.cache/uv" 2>/dev/null || true
    chmod -R 755 "${HOME}/.cache/uv" 2>/dev/null || true
    if uv pip install --system --quiet diagrams matplotlib pillow checkov 2>&1; then
        step_done "Installed via uv (diagrams, matplotlib, pillow, checkov)"
    else
        step_warn "uv install had issues, continuing"
    fi
else
    if pip3 install --quiet --user diagrams matplotlib pillow checkov 2>&1 | tail -1; then
        step_done "Installed via pip (diagrams, matplotlib, pillow, checkov)"
    else
        step_warn "pip install had issues"
    fi
fi

# ─── Step 5: PowerShell modules ──────────────────────────────────────────────

step_start "🔧" "Installing Azure PowerShell modules..."
pwsh -NoProfile -Command "
    \$ErrorActionPreference = 'SilentlyContinue'
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    \$modules = @('Az.Accounts', 'Az.Resources', 'Az.Storage', 'Az.Network', 'Az.KeyVault', 'Az.Websites')
    \$toInstall = \$modules | Where-Object { -not (Get-Module -ListAvailable -Name \$_) }
    if (\$toInstall.Count -eq 0) {
        Write-Host '        All modules already installed'
        exit 0
    }
    Write-Host \"        Installing \$(\$toInstall.Count) modules: \$(\$toInstall -join ', ')\"
    \$toInstall | ForEach-Object {
        Install-Module -Name \$_ -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -ErrorAction SilentlyContinue
    }
" && step_done "PowerShell modules installed" || step_warn "PowerShell module installation incomplete"

# ─── Step 6: Terraform security/lint tools ───────────────────────────────────

step_start "🧩" "Installing Terraform lint/security tools (tflint, trivy)..."
INSTALL_WARN=0

if command -v tflint >/dev/null 2>&1; then
    echo "        tflint already installed ($(tflint --version 2>/dev/null | head -n1))"
else
    echo "        Detecting architecture for tflint: $ARCH_LABEL"
    if curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | sudo bash >/dev/null 2>&1; then
        echo "        tflint installed"
    else
        echo "        tflint installation failed (arch: $ARCH_LABEL)"
        INSTALL_WARN=1
    fi
fi

if command -v trivy >/dev/null 2>&1; then
    echo "        trivy already installed ($(trivy --version 2>/dev/null | head -n1))"
else
    echo "        Installing trivy (arch: $ARCH_LABEL)"
    if curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin >/dev/null 2>&1; then
        echo "        trivy installed"
    else
        echo "        trivy installation failed (arch: $ARCH_LABEL)"
        INSTALL_WARN=1
    fi
fi

if [ "$INSTALL_WARN" -eq 0 ]; then
    step_done "Terraform lint/security tools ready"
else
    step_warn "Some Terraform lint/security tools failed to install"
fi

# ─── Step 7: MCP Server check ────────────────────────────────────────

step_start "💰" "Checking for MCP Servers..."
# (Simplified from original as this repo might not have the same MCP path yet)
if [ -d "${PWD}/mcp/azure-pricing-mcp" ]; then
    step_done "MCP directory found"
else
    step_done "No local MCP servers to configure"
fi

# ─── Step 8: Python dependencies (authoritative) ─────────────────────────────

step_start "📦" "Verifying Python dependencies..."
if [ -f "${PWD}/requirements.txt" ]; then
    uv pip install --system --quiet -r "${PWD}/requirements.txt"
    step_done "Python dependencies installed from requirements.txt"
else
    step_done "No requirements.txt found"
fi

# ─── Step 9: Azure CLI defaults ──────────────────────────────────────────────

step_start "☁️ " "Configuring Azure CLI..."
if az config set defaults.location=swedencentral --only-show-errors 2>/dev/null; then
    az config set auto-upgrade.enable=no --only-show-errors 2>/dev/null || true
    step_done "Default location: swedencentral"
else
    step_warn "Azure CLI config skipped (not authenticated)"
fi

# ─── Step 10: Final verification ─────────────────────────────────

step_start "🔍" "Verifying installations..."

printf "        %-15s %s\n" "Platform:" "$OS/$ARCH ($ARCH_LABEL)"
printf "        %-15s %s\n" "Azure CLI:" "$(az --version 2>/dev/null | head -n1 || echo '❌ not installed')"
printf "        %-15s %s\n" "Bicep:" "$(az bicep version 2>/dev/null | head -n1 || echo '❌ not installed')"
printf "        %-15s %s\n" "PowerShell:" "$(pwsh --version 2>/dev/null || echo '❌ not installed')"
printf "        %-15s %s\n" "Python:" "$(python3 --version 2>/dev/null || echo '❌ not installed')"
printf "        %-15s %s\n" "Node.js:" "$(node --version 2>/dev/null || echo '❌ not installed')"
printf "        %-15s %s\n" "Terraform:" "$(terraform version -json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('terraform_version','unknown'))" || echo '❌ not installed')"
printf "        %-15s %s\n" "tflint:" "$(tflint --version 2>/dev/null | head -n1 || echo '❌ not installed')"
printf "        %-15s %s\n" "trivy:" "$(trivy --version 2>/dev/null | head -n1 || echo '❌ not installed')"
printf "        %-15s %s\n" "GitHub CLI:" "$(gh --version 2>/dev/null | head -n1 || echo '❌ not installed')"
printf "        %-15s %s\n" "uv:" "$(uv --version 2>/dev/null || echo '❌ not installed')"
printf "        %-15s %s\n" "Pandoc:" "$(pandoc --version 2>/dev/null | head -n1 || echo '❌ not installed')"
printf "        %-15s %s\n" "Mermaid CLI:" "$(mmdc --version 2>/dev/null | head -n1 || echo '❌ not installed')"
printf "        %-15s %s\n" "Checkov:" "$(checkov --version 2>/dev/null || echo '❌ not installed')"
printf "        %-15s %s\n" "graphviz:" "$(dot -V 2>&1 | head -n1 || echo '❌ not installed')"
printf "        %-15s %s\n" "Playwright:" "$(npx playwright --version 2>/dev/null || echo '❌ not installed')"

step_done "All verifications complete"

# ─── Summary ─────────────────────────────────────────────────────────────────

TOTAL_ELAPSED=$(( $(date +%s) - SETUP_START ))
MINUTES=$((TOTAL_ELAPSED / 60))
SECONDS_REMAINING=$((TOTAL_ELAPSED % 60))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
    printf " ✅ Setup complete! %d/%d steps passed (%dm %ds)\n" "$PASS_COUNT" "$TOTAL_STEPS" "$MINUTES" "$SECONDS_REMAINING"
elif [ "$FAIL_COUNT" -eq 0 ]; then
    printf " ⚠️  Setup complete with warnings: %d passed, %d warnings (%dm %ds)\n" "$PASS_COUNT" "$WARN_COUNT" "$MINUTES" "$SECONDS_REMAINING"
else
    printf " ❌ Setup complete with errors: %d passed, %d warnings, %d failed (%dm %ds)\n" "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT" "$MINUTES" "$SECONDS_REMAINING"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
