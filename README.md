<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&height=220&color=0:121212,50:0078D4,100:00B7C3&text=The%20Ultimate%20CSA%20Toolkit&fontSize=48&fontColor=FFFFFF&fontAlignY=38&desc=Architectural%20Engineering%20at%20Scale&descAlignY=58" width="100%" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Microsoft-Employee-0078D4?style=flat-square&logo=microsoft&logoColor=white" />
  <img src="https://img.shields.io/badge/Role-Azure_Infrastructure_Architect-0078D4?style=flat-square&logo=microsoftazure&logoColor=white" />
</p>

<p align="center">
  <strong>The ultimate toolkit for the modern Cloud Solution Architect.</strong>
</p>

<p align="center">
  <i>Hi, I'm Jonathan. I work at Microsoft as an Azure Infrastructure Architect. This repository is my personal collection of tools, patterns, and automation scripts designed to solve high-scale infrastructure challenges with precision and speed.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/github/license/jonathan-vella/the-ultimate-csa-toolkit?style=flat-square&color=blue" />
  <img src="https://img.shields.io/github/stars/jonathan-vella/the-ultimate-csa-toolkit?style=flat-square" />
  <img src="https://img.shields.io/github/forks/jonathan-vella/the-ultimate-csa-toolkit?style=flat-square" />
  <img src="https://img.shields.io/github/last-commit/jonathan-vella/the-ultimate-csa-toolkit?style=flat-square" />
  <br />
  <a href="https://github.com/jonathan-vella/the-ultimate-csa-toolkit/fork">
    <img src="https://img.shields.io/badge/Fork-Now-orange?style=flat-square&logo=github" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Architecture-as--Code-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white" />
  <img src="https://img.shields.io/badge/Python-3.14-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/Dev_Container-Optimized-59666C?style=for-the-badge&logo=visualstudiocode&logoColor=white" />
</p>

---

## 🚀 Key Capabilities

| 🏗️ Architecture as Code                                                               | 📄 High-Fidelity Publishing                                                                   | 🛠️ Enterprise Tooling                                                                           |
| :------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------- |
| **Python Diagrams**: Create cloud architecture diagrams using the `diagrams` library. | **Pandoc + Mermaid**: Convert Markdown to Word/HTML with browser-rendered diagrams. | **Declared Stack**: Python 3.14 (`uv`), Node 24 LTS, PowerShell 7.6, Azure CLI, and GitHub CLI. |
| **Graphviz Rendering**: High-quality SVG/PNG output for design reviews.               | **Enterprise Layouts**: Automatic TOC, page breaks, and cover pages for RFP-grade reports.    | **Cloud-Ready**: Native support for Azure infrastructure operations and automation.             |

## 🛠 Quick Start

> [!IMPORTANT]
> This environment is designed to run in **VS Code Dev Containers**. The default image is **Azure Linux 4 preview**, which Microsoft limits to evaluation/testing, not production. Native ARM64 builds and automated workflows pass through CFS; migration acceptance remains incomplete until native x64 and real editor/extension activation are verified.

1.  **Launch**: Open folder in VS Code and click **"Reopen in Container"**.
2.  **Verify**: Post-create runs the required workflow checks. To repeat them:
    ```bash
    bash /opt/csa-toolkit/smoke-test.sh
    ```
3.  **Work**: Keep your diagrams, Azure scripts and conversion inputs in descriptive local folders. Workspace-specific `package.json` dependencies are installed at post-create; a root `requirements.txt` is installed into the workspace `.venv`, which you should select for those scripts.

For targeted diagnostics, `smoke-test.sh --without-browsers` checks non-browser workflows only. It is explicitly partial validation, not an adoption pass. Publishing scripts/output folders are local content, not part of this repository's tracked baseline.

For editor acceptance, run `bash .devcontainer/test-editor.sh` in the **VS Code integrated terminal inside the Dev Container**. It reruns the complete automated workflows, prints the configured extension IDs and prompts for manual checks of activation, language tooling, previews, MCP and workspace/cache behavior. Type `PASS` only after exercising each group; any other answer fails acceptance. The script cannot automatically prove extension activation or native execution, and its success depends on those confirmations. Repeat on native ARM64 and native x64; no cloud deployment or credential sharing is needed.

## 🧰 The Toolbox

| Category     | Tools & Technologies                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Cloud**    | ![Azure CLI](https://img.shields.io/badge/-Azure_CLI-%230089D6?style=flat-square&logo=microsoft-azure&logoColor=white) ![PowerShell](https://img.shields.io/badge/-PowerShell-%235391FE?style=flat-square&logo=powershell&logoColor=white) ![Bicep](https://img.shields.io/badge/-Bicep-%230078D4?style=flat-square&logo=microsoft-azure&logoColor=white) ![Terraform](https://img.shields.io/badge/-Terraform-%237B42BC?style=flat-square&logo=terraform&logoColor=white) |
| **Docs**     | ![Pandoc](https://img.shields.io/badge/-Pandoc-%23E1523D?style=flat-square&logo=pandoc&logoColor=white) ![Mermaid](https://img.shields.io/badge/-Mermaid-%23FF3670?style=flat-square&logo=mermaid&logoColor=white) ![Markdown](https://img.shields.io/badge/-Markdown-%23000000?style=flat-square&logo=markdown&logoColor=white)                                                                                                                                           |
| **Logic**    | ![Python](https://img.shields.io/badge/-Python_3.14-%233776AB?style=flat-square&logo=python&logoColor=white) ![uv](https://img.shields.io/badge/-uv-%23000000?style=flat-square&logo=python&logoColor=white) ![Node.js](https://img.shields.io/badge/-Node.js_24_LTS-%23339933?style=flat-square&logo=node.js&logoColor=white)                                                                                                                                                 |
| **Diagrams** | ![Graphviz](https://img.shields.io/badge/-Graphviz-%231B72BE?style=flat-square&logo=graphviz&logoColor=white) ![Diagrams](https://img.shields.io/badge/-Architecture_Diagrams-%23000000?style=flat-square&logo=diagrams&logoColor=white)                                                                                                                                                                                                                                   |

## 💡 How It Works

<details>
<summary><strong>📐 Architecture Diagrams via Code</strong></summary>

Combine the power of Python and Graphviz to design enterprise clouds.

```python
with Cluster("Azure"):
    hub = VNet("Hub")
    spoke = VNet("Spoke")
    hub >> spoke
```

</details>

<details>
<summary><strong>🖋 Professional Publishing Pipeline</strong></summary>

Automated workflow that takes your Markdown and transforms it into RFP-grade reports.

1. **Source Markdown**: Written in human-readable Markdown.
2. **Mermaid Rendering**: Browser-based rendering of diagrams into high-fidelity PNGs.
3. **Pandoc Assembly**: Heavy-duty conversion with custom Lua filters and CSS styling.
4. **Final Output**: Document-ready DOCX and responsive HTML.
</details>

<details>
<summary><strong>🏗 Enterprise Dev Container</strong></summary>

Azure Linux 4 preview container configured with:

- **Architecture**: Official x64/ARM64 image and release assets; native ARM64 component/workflow checks have run, but complete native dual-architecture/editor acceptance remains open.
- **Automation**: Azure CLI, standalone Bicep shared with Azure CLI/PowerShell, six Az modules, Terraform, Terragrunt, TFLint, Trivy and GitHub CLI. No additional Azure CLI extensions are declared.
- **Development**: nvm, npm, Yarn, pnpm and native Node build tools are preserved. common-utils retains the shell/development utilities.
- **Dependencies**: Pinned image digest and verified binary checksums; locked Python/npm graphs. Native OS repositories and transitive Az dependencies can still change, so this is not a fully immutable package snapshot.
- **Azure configuration**: Container environment variables select the shared Bicep binary and disable CLI auto-upgrades without explicitly overwriting those settings in the host-mounted `.azure/config`. Azure CLI may persist its own defaults when used.
</details>

## Container builds and updates

`.devcontainer/Dockerfile` provisions native DNF5 packages and the toolchain. Application-tool versions and binary checksums live in `tool-versions.env` and `releases.sha256`; Python and Node dependencies use `uv.lock` and `package-lock.json`. The retained common-utils Feature uses `devcontainer-lock.json`. Node/nvm are installed directly before the locked npm tools, preserving version management without a second Feature installation replacing the declared package managers.

Update the declarations together and rebuild through Dev Containers. `update-tools.sh` explains this workflow and runs acceptance checks; it does not silently upgrade global tools in a running container. Update `.devcontainer/.npmrc`'s UTC `before` cutoff to more than seven days before the update, then select eligible stable top-level versions. Regenerate Python locks with `uv lock --project .devcontainer --upgrade --default-index https://packagefeedproxy.microsoft.io/pypi/simple/`. Regenerate npm locks from scratch in a temporary directory containing `package.json` and `.npmrc` with `npm install --package-lock-only --ignore-scripts`, then copy back the reviewed lock; an existing lock can retain too-recent transitive versions. Run `uv run --no-project .devcontainer/check-package-age.py` and review all changes. The image digest, DNF Azure CLI version, runtime versions, release hashes, Yarn pin and browser-package revisions need coherent review too.

### Microsoft CFS package routing

npm, pnpm, Yarn/Corepack and uv use the approved `packagefeedproxy.microsoft.io` endpoints for container builds and workspace installs. Python uses `uv sync --locked` with a proxy-native lock and verified artifact hashes. npm retains its lock integrity checks. Yarn itself is installed from the locked `@yarnpkg/cli-dist` package because CFS returns 404 for the version-metadata endpoint requested by Corepack; Corepack remains installed. TLS verification stays enabled. The seven-day age policy applies to the toolkit's reviewed locks; workspace projects retain their own dependency declarations.

Microsoft CFS only exposes releases older than seven days. The approved policy is the newest available stable releases meeting that age, not the public registry's unrestricted `latest`. The current cutoff is `2026-10-01T13:05:02Z`; Playwright is `1.63.0`, pnpm `12.8.2`, and Checkov `3.3.22`. All locked transitive versions are audited too, including the aiohttp age constraint in `pyproject.toml`. CFS's PyPI replica timestamps can reflect ingestion rather than original publication, so `check-package-age.py` reads upstream PyPI metadata for dates without downloading packages there; npm dates and availability come from CFS. Do not bypass the proxy or use an alpha reported as `latest`. Azure Artifacts `ms-feed-*` pages are for browsing only, never package-manager configuration. Artifact URLs returned by the configured proxy can legitimately reference Azure Artifacts storage.

PowerShell Gallery installs use HTTP/1 during the build, which succeeded after HTTP/2 attempts encountered TLS EOF errors on this network. This setting is scoped to the module installation command; certificate verification is unchanged. The NuGet proxy is not assumed to mirror PowerShell Gallery modules.

Native ARM64 validation covers the real Dockerfile, the actual Dev Container Feature build, sandboxed browser/rendering workflows and lifecycle checks with fresh/stale cache volumes. Credential mounts were excluded from successful lifecycle fixtures; real editor activation and native x64 execution are still required. npm also reports advisories in the eligible dependency graph; functional acceptance does not mean a vulnerability-free toolkit.

Playwright's Azure Linux installation uses an unsupported-OS Ubuntu fallback, with native libraries supplied by DNF rather than `install --with-deps`. Puppeteer/Mermaid has a separate matched Chrome/cache installation. Full smoke checks require sandboxed launches. The approved `chromium-seccomp.json` retains Docker's default restrictions and adds only `clone`, `setns`, and `unshare` permissions for Chromium's user namespaces; native ARM64 sandboxed Playwright/Puppeteer and Mermaid renders pass with it. Neither `--no-sandbox` nor privileged/unconfined settings or extra capabilities are enabled. Do not disable certificate verification to work around dependency-download failures.

The seccomp policy is derived from [Moby's default profile at 6fe7deb](https://github.com/moby/profiles/blob/6fe7deb1b9fb7c0397a4593480d7d22b9ee8caef/seccomp/default.json), licensed under Apache-2.0 (see `.devcontainer/LICENSE.seccomp`), with the namespace exception described in [Playwright's Docker guidance](https://playwright.dev/docs/docker). Review it against Docker's current default when upgrading the container runtime.

Validate the final **actual Dev Container** on native x64 and ARM64, including all configured extensions, UID/GID adjustment and existing/fresh cache volumes. Direct Dockerfile builds alone do not apply Features, mounts or editor setup. Version prints and scanner startup are not functional acceptance or a guarantee of Azure Linux 4 vendor support. Trivy's local smoke fixture uses embedded configuration checks; OS vulnerability advisory coverage is a separate check.

References: [official image/preview status](https://learn.microsoft.com/en-us/azure/azure-linux/container-images-overview), [DNF/repositories](https://learn.microsoft.com/en-us/azure/azure-linux/package-repositories), [Playwright OS requirements](https://playwright.dev/docs/intro#system-requirements), [browser sandbox guidance](https://pptr.dev/troubleshooting).

---

<p align="center">
  <img src="https://img.shields.io/badge/Powered_by-GitHub_Copilot-000000?style=for-the-badge&logo=github&logoColor=white" />
  <img src="https://img.shields.io/badge/Maintained_for-Azure_Architects-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white" />
</p>

<p align="center">
  <i>Built with ⚡ for High-Performance Azure Architecture</i>
</p>
