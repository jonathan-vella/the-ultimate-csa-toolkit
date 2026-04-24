# The Ultimate CSA Toolkit - AI Agent Instructions

## Project Guidelines

### Code Style

- **Python**: Use standard PEP 8 naming conventions. Prefer `pathlib` for file operations.
- **PowerShell**: Use PascalCase for function names and strictly use official `Az` module commands.
- **Markdown**: Use consistent heading levels and list structures for documentation.

### Architecture

- **Environment**: Container-first development repo using VS Code Dev Containers (Ubuntu 24.04 LTS).
- **Core Strategy**: Always use the **latest and greatest** available stable tooling.
- **Base Image**: `mcr.microsoft.com/devcontainers/base:ubuntu-24.04`.
- **Pre-installed Tools**:
  - **Azure CLI**: Version `latest` via devcontainer feature. Includes `bicep`.
  - **Azure PowerShell**: Latest `Az` module via PowerShell 7+.
  - **Python 3.13**: Managed via `uv` (fast package manager).
  - **Node.js 22+ (LTS)**: Core for modern web/docs tooling.
  - **Pandoc**: Universal document converter with Mermaid CLI support.
  - **Playwright**: Included for high-fidelity rendering of browser-based diagrams.

### Build and Test

To verify the environment is ready for specific tasks, run these commands:

- **Azure CLI**: `az --version`.
- **Azure PowerShell**: `pwsh -c "import-module Az; Get-Module Az"`.
- **Python uv**: `uv --version`.
- **Pandoc & Mermaid**: `pandoc --version` and `mmdc --version`.

### Strict Standards

- **Zero-Stale Policy**: Never use deprecated or "legacy" npm/pip packages (e.g., use `uv` instead of old `pip`, use `@mermaid-js/mermaid-cli` instead of old filters).
- **Reproducibility**: All required system/browser dependencies for diagram rendering must be in `.devcontainer/devcontainer.json`.
- **Performance**: Use `uv` for all Python operations as a faster, more modern standard.

### Project Conventions

- **Strict Git Tracking**: By design, this repo only tracks foundational configuration files.
  - Tracked: `README.md`, `.gitignore`, `.devcontainer/`, `.github/copilot-instructions.md`.
  - Untracked: All other folders (e.g., `diagrams/`, `scripts/`) are ignored to keep the repository clean.
- **File Organization**: Use descriptive subfolders like `diagrams/` for Python code, `azure/` for Az scripts, and `conversions/` for Pandoc tasks.
- **Reproducibility**: Ensure all required dependencies are added to `.devcontainer/devcontainer.json`.

### Major Components

1. **Python Diagrams**: Primary tool for architectural diagrams as code. Uses Graphviz.
2. **Azure Integration**: Dual-support for CLI and PowerShell (ARM64/x64 compatible).
3. **Document Conversion**: Pandoc for converting Markdown to various formats.
4. **General Scripting**: Python 3.12 for automation.
