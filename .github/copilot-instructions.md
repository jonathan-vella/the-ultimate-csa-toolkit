# The Ultimate CSA Toolkit - AI Agent Instructions

## Project Guidelines

### Code Style

- **Python**: Use standard PEP 8 naming conventions. Prefer `pathlib` for file operations.
- **PowerShell**: Use PascalCase for function names and strictly use official `Az` module commands.
- **Markdown**: Use consistent heading levels and list structures for documentation.

### Architecture

- **Environment**: Container-first development using Azure Linux 4 preview; evaluation/testing only, not production.
- **Core Strategy**: Use current stable tooling through reviewed version/lock updates and verified rebuilds, not mutable startup installs.
- **Base Image**: Official `mcr.microsoft.com/azurelinux-beta/base/core:4.0`, pinned by multi-architecture digest in `.devcontainer/Dockerfile`. Use DNF5 and native base/microsoft repositories, not Ubuntu packages or assumed RHEL compatibility.
- **Pre-installed Tools**:
  - **Azure CLI**: Native RPM; standalone Bicep is shared through PATH with Azure CLI and PowerShell.
  - **Azure PowerShell**: PowerShell 7.6 and the six declared Az modules, installed all-users.
  - **Python 3.14**: uv-managed interpreter and a locked tooling environment, separate from system/Azure CLI Python.
  - **Node.js 24 LTS**: nvm/npm/Yarn/pnpm and build tools; locked documentation/browser packages.
  - **Pandoc**: Universal document converter with Mermaid CLI support.
  - **Playwright**: Included for high-fidelity rendering of browser-based diagrams.

### Build and Test

Run `bash /opt/csa-toolkit/smoke-test.sh` as the Dev Container user for required real-workflow checks. `--without-browsers` is partial diagnostics only. Also verify actual VS Code/extension activation, mounts and UID/GID reconciliation on native x64 and ARM64; do not substitute emulated execution or asset availability.

For individual diagnostics:

- **Azure CLI**: `az --version`.
- **Azure PowerShell**: import Az.Accounts, Az.Resources, Az.Storage, Az.Network, Az.KeyVault and Az.Websites; the aggregate `Az` module is not declared.
- **Python uv**: `uv --version`.
- **Pandoc & Mermaid**: `pandoc --version` and `mmdc --version`.

### Strict Standards

- **Zero-Stale Policy**: Never use deprecated or "legacy" npm/pip packages (e.g., use `uv` instead of old `pip`, use `@mermaid-js/mermaid-cli` instead of old filters).
- **Reproducibility**: Declare system/browser dependencies in `.devcontainer/Dockerfile`, binary versions/checksums in the tracked installation files, and language dependencies in tracked manifests/locks. Keep updates coherent and required failures nonzero.
- **Package routing**: Use `https://packagefeedproxy.microsoft.io/npm/` for npm/pnpm/Yarn/Corepack and `https://packagefeedproxy.microsoft.io/pypi/simple/` for uv, or an approved team-owned feed. Use the newest available stable releases older than seven days, including transitive versions. Update `.npmrc`'s cutoff and run `check-package-age.py` when regenerating locks. Python uses proxy-native `uv sync --locked` with artifact hash verification; replica ingestion dates are not original publication dates. Never configure `ms-feed-*` browse URLs or bypass CFS.
- **Browser isolation**: Separate Playwright/Puppeteer browser caches. The approved seccomp profile adds only Chromium's clone/setns/unshare permissions to Docker defaults; keep sandboxing enabled. Do not introduce privileged/unconfined containers, broad capabilities or bypass TLS verification.
- **Acceptance**: Native ARM64 CFS builds and automated workflows pass; native x64 and real editor/extension activation remain open migration gates. Preview acceptance is not vendor certification, and npm advisory findings are not cleared by workflow tests.
- **Performance**: Use `uv` for all Python operations as a faster, more modern standard.

### Project Conventions

- **Strict Git Tracking**: By design, this repo only tracks foundational configuration files.
  - Tracked: `README.md`, `.gitignore`, `.devcontainer/`, `.github/copilot-instructions.md`.
  - Untracked: All other folders (e.g., `diagrams/`, `scripts/`) are ignored to keep the repository clean.
- **File Organization**: Use descriptive subfolders like `diagrams/` for Python code, `azure/` for Az scripts, and `conversions/` for Pandoc tasks.
- **Reproducibility**: Keep dependency/build/smoke-test files under the tracked `.devcontainer/` allowlist. Do not silently remove implicit tools such as Terragrunt or nvm/Yarn/pnpm.

### Major Components

1. **Python Diagrams**: Primary tool for architectural diagrams as code. Uses Graphviz.
2. **Azure Integration**: Dual-support for CLI and PowerShell (ARM64/x64 compatible).
3. **Document Conversion**: Pandoc for converting Markdown to various formats.
4. **General Scripting**: Python (latest stable) for automation.
