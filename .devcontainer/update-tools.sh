#!/bin/bash
set -e

# Platform detection
ARCH=$(uname -m)
OS=$(uname -s)
case "$ARCH" in
    x86_64)  ARCH_LABEL="amd64" ;;
    aarch64) ARCH_LABEL="arm64" ;;
    arm64)   ARCH_LABEL="arm64" ;;
    *)       ARCH_LABEL="$ARCH" ;;
esac

echo "🔄 Updating development tools..."
echo "   Platform: $OS/$ARCH ($ARCH_LABEL)"
echo ""

# Track failures
FAILURES=()

# Update Azure CLI
echo "📦 Checking Azure CLI..."
CURRENT_AZ=$(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo "unknown")
echo "  ℹ️  Current version: $CURRENT_AZ (managed by devcontainer feature, auto-upgrade disabled)"

# Update Bicep
echo "📦 Updating Bicep..."
if az bicep upgrade --only-show-errors 2>/dev/null; then
    echo "   ✅ Bicep updated"
else
    echo "  ⚠️  Bicep update skipped or failed"
    FAILURES+=("Bicep")
fi

# Update Python packages
echo "📦 Updating Python packages..."
if uv pip install --system --upgrade --quiet checkov diagrams 2>/dev/null; then
    echo "   ✅ Python packages updated (checkov, diagrams)"
else
    echo "   ⚠️  Python package updates had issues"
    FAILURES+=("Python packages")
fi

# Update markdownlint-cli2
echo "📦 Updating markdownlint-cli2..."
if sudo npm update -g markdownlint-cli2 --silent 2>/dev/null; then
    echo "   ✅ markdownlint-cli2 updated"
else
    echo "   ⚠️  markdownlint-cli2 update had issues"
    FAILURES+=("markdownlint-cli2")
fi

# Update tflint
echo "📦 Updating tflint..."
if curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | sudo bash >/dev/null 2>&1; then
    echo "   ✅ tflint updated"
else
    echo "   ⚠️  tflint update had issues"
    FAILURES+=("tflint")
fi

# Update trivy
echo "📦 Updating trivy..."
if curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin >/dev/null 2>&1; then
    echo "   ✅ trivy updated"
else
    echo "   ⚠️  trivy update had issues"
    FAILURES+=("trivy")
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ ${#FAILURES[@]} -eq 0 ]; then
    echo "✅ All tool updates completed successfully!"
else
    echo "⚠️  Updates completed with some issues:"
    for fail in "${FAILURES[@]}"; do
        echo "   - $fail"
    done
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show current versions
echo "📊 Current tool versions:"
printf "   %-15s %s\n" "Azure CLI:" "$(az version --query '\"azure-cli\"' -o tsv 2>/dev/null || echo 'unknown')"
printf "   %-15s %s\n" "Bicep:" "$(az bicep version 2>/dev/null || echo 'unknown')"
printf "   %-15s %s\n" "Checkov:" "$(checkov --version 2>/dev/null || echo 'unknown')"
printf "   %-15s %s\n" "tflint:" "$(tflint --version 2>/dev/null | head -n1 || echo 'unknown')"
printf "   %-15s %s\n" "trivy:" "$(trivy --version 2>/dev/null | head -n1 || echo 'unknown')"
printf "   %-15s %s\n" "Python:" "$(python3 --version 2>/dev/null || echo 'unknown')"
echo ""
