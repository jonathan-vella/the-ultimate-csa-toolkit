#!/usr/bin/env bash
set -euo pipefail
trap 'printf "Tool installation failed at line %s\n" "$LINENO" >&2' ERR
source /opt/csa-toolkit/tool-versions.env
case "${1:-}" in
    amd64) node_arch=x64; uv_arch=x86_64; trivy_arch=64bit ;;
    arm64) node_arch=arm64; uv_arch=aarch64; trivy_arch=ARM64 ;;
    *) printf 'Unsupported architecture: %s\n' "${1:-unset}" >&2; exit 1 ;;
esac
arch=$1
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

download() {
    local name=$1 url=$2 hash
    hash=$(awk -v name="$name" '$2 == name { print $1 }' /opt/csa-toolkit/releases.sha256)
    [[ "$hash" =~ ^[a-f0-9]{64}$ ]] || { printf 'Missing checksum: %s\n' "$name" >&2; exit 1; }
    curl --fail --show-error --location --retry 3 --connect-timeout 30 --max-time 300 "$url" -o "$name"
    printf '%s  %s\n' "$hash" "$name" | sha256sum --check --strict -
}

download "bicep-$arch" "https://github.com/Azure/bicep/releases/download/v${BICEP_VERSION}/bicep-linux-${node_arch}"
install -m 0755 "bicep-$arch" /usr/local/bin/bicep
download "powershell-$arch" "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-${node_arch}.tar.gz"
mkdir -p /opt/microsoft/powershell/7
tar -xzf "powershell-$arch" -C /opt/microsoft/powershell/7
chmod +x /opt/microsoft/powershell/7/pwsh
ln -s /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh
download "pandoc-$arch" "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-${arch}.tar.gz"
tar -xzf "pandoc-$arch"
install -m 0755 "pandoc-${PANDOC_VERSION}/bin/pandoc" /usr/local/bin/pandoc
download "uv-$arch" "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${uv_arch}-unknown-linux-gnu.tar.gz"
tar -xzf "uv-$arch"
install -m 0755 "uv-${uv_arch}-unknown-linux-gnu/uv" "uv-${uv_arch}-unknown-linux-gnu/uvx" /usr/local/bin/

download nvm "https://github.com/nvm-sh/nvm/archive/refs/tags/v${NVM_VERSION}.tar.gz"
mkdir -p "$NVM_DIR"
tar -xzf nvm --strip-components=1 -C "$NVM_DIR"
download "node-$arch" "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.xz"
mkdir -p "$NVM_DIR/versions/node/v${NODE_VERSION}" "$NVM_DIR/alias"
tar -xJf "node-$arch" --strip-components=1 -C "$NVM_DIR/versions/node/v${NODE_VERSION}"
ln -s "$NVM_DIR/versions/node/v${NODE_VERSION}" "$NVM_DIR/current"
printf '%s\n' "$NODE_VERSION" > "$NVM_DIR/alias/default"
printf 'export NVM_DIR=%q\n[ ! -s "$NVM_DIR/nvm.sh" ] || . "$NVM_DIR/nvm.sh"\n' "$NVM_DIR" > /etc/profile.d/nvm.sh
printf '\n. /etc/profile.d/nvm.sh\n' >> /home/vscode/.bashrc
printf '\n. /etc/profile.d/nvm.sh\n' >> /home/vscode/.zshrc
chown -R vscode:vscode "$NVM_DIR"

download "terraform-$arch" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${arch}.zip"
unzip -q "terraform-$arch" -d terraform
install -m 0755 terraform/terraform /usr/local/bin/terraform
download "terragrunt-$arch" "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${arch}"
install -m 0755 "terragrunt-$arch" /usr/local/bin/terragrunt
download "tflint-$arch" "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${arch}.zip"
unzip -q "tflint-$arch" -d tflint
install -m 0755 tflint/tflint /usr/local/bin/tflint
download "trivy-$arch" "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${trivy_arch}.tar.gz"
mkdir trivy
tar -xzf "trivy-$arch" -C trivy
install -m 0755 trivy/trivy /usr/local/bin/trivy
download "gh-$arch" "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${arch}.tar.gz"
tar -xzf "gh-$arch"
install -m 0755 "gh_${GH_VERSION}_linux_${arch}/bin/gh" /usr/local/bin/gh

download lsb-release "https://deb.debian.org/debian/pool/main/l/lsb-release-minimal/lsb-release-minimal_${LSB_RELEASE_VERSION}.orig.tar.gz"
tar -xzf lsb-release
install -m 0755 "lsb-release-minimal-${LSB_RELEASE_VERSION}/lsb_release" /usr/local/bin/lsb_release
install -Dm 0644 "lsb-release-minimal-${LSB_RELEASE_VERSION}/LICENSE.txt" /usr/local/share/licenses/lsb-release-minimal/LICENSE.txt
