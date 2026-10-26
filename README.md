<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&height=220&color=0:121212,50:0078D4,100:00B7C3&text=The%20Ultimate%20CSA%20Toolkit&fontSize=48&fontColor=FFFFFF&fontAlignY=38&desc=Design.%20Automate.%20Render.%20Deliver.&descAlignY=58" width="100%" alt="The Ultimate CSA Toolkit: Design. Automate. Render. Deliver." />
</p>

<p align="center">
  <strong>Sketch the architecture. Shape the infrastructure. Tell the story.</strong><br />
  One Azure-focused workspace for diagrams, IaC, validation and polished deliverables.
</p>

<p align="center">
  <a href="#environment-status"><img src="https://img.shields.io/badge/Azure_Linux-4_preview-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white" alt="Azure Linux 4 preview" /></a>
  <img src="https://img.shields.io/badge/Python-3.14-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python 3.14" />
  <img src="https://img.shields.io/badge/Node.js-24_LTS-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js 24 LTS" />
  <a href="#environment-status"><img src="https://img.shields.io/badge/Refresh-x64_workflows_pass%20%7C%20more_acceptance_pending-F2C811?style=for-the-badge" alt="Refresh x64 automated workflows pass; additional acceptance pending" /></a>
</p>

<p align="center">
  <a href="#-get-started">Get started</a> ·
  <a href="#-from-idea-to-deliverable">See the workflow</a> ·
  <a href="#-the-toolbox">Explore the toolbox</a> ·
  <a href="#-build-something">Try an example</a> ·
  <a href="#-under-the-hood">Under the hood</a>
</p>

---

## ✨ From idea to deliverable

I'm Jonathan, a Microsoft Azure Infrastructure Architect. This is my personal, container-first toolkit for moving from a cloud idea to something you can validate, render and share—without stitching together a different environment for every step.

| 01 · **Design** | 02 · **Build** | 03 · **Verify** | 04 · **Deliver** |
| :--- | :--- | :--- | :--- |
| Python Diagrams, Graphviz and Mermaid turn an idea into a picture. | Azure CLI, Bicep, PowerShell/Az and Terraform turn a design into infrastructure code. | Checkov, Trivy, TFLint and real browser renders help catch issues before hand-off. | Pandoc takes Markdown to HTML or DOCX; SVG and PNG make diagrams easy to share. |

<p align="center"><strong>One ready-to-use environment. Four connected parts of the cloud-architect workflow.</strong></p>

### 🌍 Environment status

> [!WARNING]
> **Azure Linux 4 is a preview image for evaluation and testing—not production.** The refreshed native x64 Docker image passes the full automated workflows, including sandboxed browser rendering. A complete Dev Containers/Feature rebuild hit upstream HTTP 504 download errors. Refreshed ARM64 and interactive VS Code acceptance are still pending; earlier ARM64 results were for the previous configuration. Playwright works in the earlier ARM64 checks but does not officially support Azure Linux.

## 🚀 Get started

**You’ll need:** Docker, VS Code, and the Dev Containers extension.

```bash
git clone https://github.com/jonathan-vella/the-ultimate-csa-toolkit.git
cd the-ultimate-csa-toolkit
```

### Microsoft employees: host setup first

Connect to your approved corporate network/VPN as required. **Fully exit all VS Code windows** so the new process inherits the package-feed settings. From the cloned repository, run the host launcher—not `code .`, and not from a container or VS Code integrated terminal.

| Host | Run |
| :--- | :--- |
| Windows · PowerShell 5.1+ | `.\.devcontainer\open-microsoft.ps1` |
| Linux, macOS or WSL | `bash .devcontainer/open-microsoft.sh` |

The launcher opens VS Code with Microsoft's CFS package feeds selected for image builds and container setup. CFS is also the toolkit default. Launchers only need the host `code` command; they do not install packages, persist host settings, alter credentials, disable TLS checks or fall back to public registries. Windows PowerShell supports 5.1 and restores the caller's environment; WSL forwards the selections to Windows VS Code.

Use the launcher whenever starting a fresh VS Code process for this project. If policy blocks a script, use your organization's approved execution method—do not bypass it. Other organizations can configure an approved source under [Package sources](#package-sources).

### Open and check the toolkit

1. In VS Code, open the cloned folder and run **Dev Containers: Rebuild and Reopen in Container**.
2. Wait for the initial build and post-create checks to finish.
3. Start creating in `diagrams/`, `azure/` or `conversions/`—those work folders are yours to keep and are intentionally not tracked.

> [!NOTE]
> Package installs use Microsoft's **CFS proxy** by default. Your network also needs the image registry, upstream binary/browser downloads and CFS-returned artifact endpoints. Source checks stop the setup if the selected feeds do not match reviewed locks.

For a separate minimal Windows-to-WSL setup, see the
[Azure Linux 4 WSL bootstrap](.devcontainer/wsl/README.md). It provisions native
Azure/GitHub CLIs, Copilot and Bicep, with weekly DNF updates and resumable personal
dotfiles setup. It does not install this entire dev-container toolchain.

### Check your environment

Run inside the container:

```bash
# Automated tool and rendering workflows, including sandboxed browsers
bash /opt/csa-toolkit/smoke-test.sh

# Interactive VS Code acceptance, from its integrated container terminal
bash .devcontainer/test-editor.sh
```

The editor check guides you through extensions, language tooling, previews, MCP, mounts and caches. Type `PASS` only after checking each group. It records your confirmation—it cannot independently prove editor activation or native hardware. Repeat on each architecture.

`smoke-test.sh --without-browsers` is partial diagnostics, not full acceptance. No acceptance check requires a cloud deployment or sharing credentials.

## 🧰 The toolbox

| Area | Included tools |
| :--- | :--- |
| ☁️ **Azure** | Azure CLI, Bicep, PowerShell 7.6 and six focused Az modules |
| 🏗️ **Infrastructure** | Terraform, Terragrunt, TFLint, Checkov and Trivy |
| 🐍 **Python** | uv-managed Python 3.14, Diagrams, matplotlib and Pillow |
| 🟩 **JavaScript** | Node 24 LTS, nvm, npm, Yarn, pnpm, Corepack and native build tools |
| 📄 **Publishing** | Pandoc, Mermaid CLI, markdownlint, Graphviz, SVG conversion and fonts |
| 🌐 **Rendering** | Separate Playwright Chromium and Puppeteer/Mermaid Chrome |
| 🛠️ **Developer experience** | GitHub CLI, Bash/Zsh, Azure-focused VS Code extensions and Microsoft Learn MCP |

Root workspace `package.json` dependencies are installed at post-create. A root `requirements.txt` gets its own workspace `.venv`; select that interpreter for those scripts. The prebuilt toolkit environment stays separate.

## 🎨 Build something

<details open>
<summary><strong>Architecture as code → SVG and PNG</strong></summary>

Save this as `diagrams/azure_architecture.py`:

```python
from pathlib import Path

from diagrams import Cluster, Diagram
from diagrams.azure.compute import AppServices
from diagrams.azure.database import SQLDatabases
from diagrams.azure.network import ApplicationGateway

output = Path(__file__).with_name("azure_architecture")
with Diagram("Azure workload", filename=str(output), outformat=["svg", "png"], show=False):
    gateway = ApplicationGateway("Ingress")
    with Cluster("Application"):
        app = AppServices("Web app")
        database = SQLDatabases("Data")
    gateway >> app >> database
```

Run `python diagrams/azure_architecture.py`. Both outputs land beside the script.

</details>

<details>
<summary><strong>Markdown + Mermaid → shareable documents</strong></summary>

Render a diagram, reference its image in your Markdown, then convert:

```bash
mmdc -i conversions/architecture.mmd -o conversions/architecture.png
pandoc conversions/report.md --resource-path=conversions -o conversions/report.docx
pandoc conversions/report.md --resource-path=conversions --standalone -o conversions/report.html
```

Custom templates, CSS and Lua filters can extend your publishing workflow. They are local project content, not a preinstalled publishing engine.

</details>

## ⚙️ Under the hood

This repository tracks the container and its setup—not your project output. Diagrams, scripts and generated documents in work folders are intentionally ignored; change `.gitignore` if you want to publish them.

### The build contract

| Files | Why they stay |
| :--- | :--- |
| `devcontainer.json`, `Dockerfile`, `post-create.sh` | Editor integration, native DNF5 provisioning and workspace initialization |
| `install-tools.sh`, `install-az-modules.ps1` | Architecture-specific binary installs and all-users Az modules |
| `tool-versions.env`, `releases.sha256` | Reviewed binary versions and verified downloads |
| `pyproject.toml`, `uv.lock`, `package.json`, `package-lock.json`, `.npmrc` | Declared language dependencies, integrity locks and CFS resolution cutoff |
| `open-microsoft.ps1`, `open-microsoft.sh` | Process-scoped Microsoft host launchers, including WSL forwarding |
| `package_sources.py`, `package-sources.json` | Selected-feed checks and reviewed locked artifact destinations |
| `devcontainer-lock.json` | Pinned common-utils Feature |
| `chromium-seccomp.json`, `LICENSE.seccomp` | Approved sandbox policy and its upstream license |
| `smoke-test.sh`, `smoke-test.py`, `smoke-browser.cjs`, `test-editor.sh` | Real workflow checks and guided editor acceptance |
| `check-package-age.py` | Publication-age audit for locked direct/transitive packages |
| `test_package_sources.py`, `test-az-modules.ps1` | Offline source/launcher regressions and mocked Az provisioning checks |

### Package sources

The [Microsoft host launcher](#microsoft-employees-host-setup-first) sets the CFS defaults. To use an approved team feed instead, set these variables in the **host process that starts VS Code**:

| Host variable | Default when unset |
| :--- | :--- |
| `CSA_NPM_REGISTRY_HOST_PATH` | `packagefeedproxy.microsoft.io/npm/` |
| `CSA_PYPI_INDEX_HOST_PATH` | `packagefeedproxy.microsoft.io/pypi/simple/` |
| `CSA_POWERSHELL_REPOSITORY_URL` | `https://packagefeedproxy.microsoft.io/powershell/v2` |

npm/Python values are host and path **without `https://`**. The PowerShell value is a full HTTPS URL. Inputs cannot contain credentials, query strings or fragments. Never put secrets in build arguments; follow the approved feed's authentication method.

The Dockerfile applies selected sources before toolkit installs and retained Feature builds; `containerEnv` carries them to workspace installs. npm, pnpm, Yarn and Corepack share npm; uv and pip share Python. The selected npm source takes precedence over `.npmrc`. The six pinned Az modules use a temporary, untrusted PowerShell repository, which is removed afterward. CFS v2 supplies package-content links; PowerShell provisioning uses `Install-Module` because PSResourceGet requests an unsupported `/package/` URL.

> **Changing a registry does not rewrite lockfiles.** `package-sources.json` records the reviewed sources and artifact URL prefixes for the toolkit locks. CFS may return Azure Artifacts download URLs; those are artifact destinations, not package-manager registry settings. Checks verify source identity, artifact destinations and integrity declarations before installing.

For an approved team feed, set the host variables, then regenerate and review `.npmrc`, both locks and `package-sources.json` together through that feed. Preserve the package-age cutoff and pins unless a reviewed update is needed. Record only artifact prefixes returned by the feed; changing the source record alone does not migrate a lock. Until all sources agree, setup fails closed—no unlocked install or public fallback. Workspace projects keep their own locks and need separate review.

The Microsoft launcher intentionally selects CFS. For an approved team feed, start a fresh VS Code process directly from a shell with those source variables set. CFS is for Microsoft corporate developer laptops/dev boxes; automated builds need an authenticated, approved team feed.

Run the offline source and launcher checks from an environment with uv, npm, Bash and PowerShell:

```bash
uv run --no-project .devcontainer/test_package_sources.py
pwsh -NoProfile -File .devcontainer/test-az-modules.ps1
```

These tests use temporary files, a stub `code` command and mocked module installs. They do not open VS Code, install packages or replace native container/editor acceptance.

<details>
<summary><strong>Package policy and reviewed updates</strong></summary>

Use the newest CFS-available **stable releases older than seven days**, not unrestricted public `latest`. The current UTC cutoff in `.npmrc` is `2026-10-01T13:05:02Z`; Playwright is `1.63.0`, pnpm `12.8.2`, and Checkov `3.3.22`. All locked transitive versions are audited too.

Updates are reviewed rebuilds, not in-place global upgrades:

1. Update the cutoff and select eligible stable pins. Review image/runtime versions, binary checksums, Azure CLI RPM and browser revisions together.
2. Regenerate Python locks with `uv lock --project .devcontainer --upgrade --default-index https://packagefeedproxy.microsoft.io/pypi/simple/`. Review age constraints such as aiohttp in `pyproject.toml`.
3. Resolve npm from a fresh lock in a temporary directory containing `package.json` and `.npmrc`: run `npm install --package-lock-only --ignore-scripts`, then copy the reviewed lock back. Existing locks can retain too-recent transitive versions.
4. Run `uv run --no-project .devcontainer/check-package-age.py`, rebuild through Dev Containers, and repeat automated/editor checks on native ARM64 and x64.

npm/pnpm/Yarn/Corepack use `https://packagefeedproxy.microsoft.io/npm/`; uv uses `https://packagefeedproxy.microsoft.io/pypi/simple/`. Python installs with proxy-native `uv sync --locked` and verified artifact hashes; npm retains lock integrity. CFS's PyPI timestamps can reflect ingestion rather than publication, so the age audit reads upstream PyPI **metadata only**, never package downloads.

Azure Artifacts `ms-feed-*` pages are for browsing, not package-manager configuration. URLs returned by CFS may legitimately reference Azure Artifacts storage. Do not bypass CFS, disable TLS verification or adopt prereleases to unblock installs. Workspace projects retain their own dependency declarations.

Yarn comes from locked `@yarnpkg/cli-dist` because Corepack's version-metadata endpoint returns 404 through CFS; Corepack remains available. PowerShell module installation uses build-scoped HTTP/1 to avoid network HTTP/2 TLS EOF errors—without weakening certificate verification.

Image/application pins are not a fully immutable OS snapshot: native repositories and transitive Az dependencies can change.

</details>

<details>
<summary><strong>Browser isolation, mounts and acceptance boundaries</strong></summary>

Playwright uses an unsupported-OS Ubuntu fallback with native libraries installed through DNF. Puppeteer/Mermaid retains its own matched Chrome/cache. Browser checks keep sandboxing enabled.

The approved seccomp profile adds only `clone`, `setns` and `unshare` permissions to [Moby's default profile at 6fe7deb](https://github.com/moby/profiles/blob/6fe7deb1b9fb7c0397a4593480d7d22b9ee8caef/seccomp/default.json), following [Playwright's Docker guidance](https://playwright.dev/docs/docker). Its Apache-2.0 license is retained in `.devcontainer/LICENSE.seccomp`. No `--no-sandbox`, privileged/unconfined mode or extra capabilities are enabled. Review the policy against Docker defaults when upgrading the runtime.

The container preserves the host `.azure` bind and named GitHub/uv caches. Environment overrides share standalone Bicep and disable CLI auto-upgrades without explicitly overwriting those host configuration settings; Azure CLI may persist its own defaults.

The previous configuration passed native ARM64 builds, sandboxed workflows, cache lifecycle checks and user-confirmed editor acceptance. The refreshed native x64 Docker image passes full automated workflows. **A complete Dev Containers/Feature rebuild, refreshed ARM64 and interactive editor acceptance remain open.** Emulation and release assets are not substitutes. Windows PowerShell 5.1 syntax checks pass; execution validation was blocked by host policy. The launcher passes in PowerShell 7 without changing that policy.

npm advisories remain in the eligible graph. Workflow success is not vulnerability-free certification. Trivy's smoke fixture uses embedded local configuration checks; vulnerability-database coverage is separate.

</details>

References: [Azure Linux images and preview boundaries](https://learn.microsoft.com/en-us/azure/azure-linux/container-images-overview) · [Native repositories](https://learn.microsoft.com/en-us/azure/azure-linux/package-repositories) · [Playwright OS requirements](https://playwright.dev/docs/intro#system-requirements) · [Puppeteer troubleshooting](https://pptr.dev/troubleshooting)

---

<p align="center">
  <strong>Draw the cloud. Build the blueprint. Share the outcome.</strong><br />
  <sub>Built for the work between an architecture idea and a confident hand-off.<br />
  A personal toolkit by Jonathan Vella—not an official Microsoft product.</sub>
</p>
