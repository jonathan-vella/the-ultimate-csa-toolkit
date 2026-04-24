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
  <img src="https://img.shields.io/badge/Python-3.13-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/Dev_Container-Optimized-59666C?style=for-the-badge&logo=visualstudiocode&logoColor=white" />
</p>

---

## 🚀 Key Capabilities

| 🏗️ Architecture as Code                                                               | 📄 High-Fidelity Publishing                                                                   | 🛠️ Enterprise Tooling                                                                           |
| :------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------- |
| **Python Diagrams**: Create cloud architecture diagrams using the `diagrams` library. | **Pandoc + Mermaid**: Convert Markdown to professional Word/HTML with full diagram rendering. | **Latest Stack**: Python 3.13 (`uv`), PowerShell 7.5, Azure CLI, and GitHub CLI pre-configured. |
| **Graphviz Rendering**: High-quality SVG/PNG output for design reviews.               | **Enterprise Layouts**: Automatic TOC, page breaks, and cover pages for RFP-grade reports.    | **Cloud-Ready**: Native support for Azure infrastructure operations and automation.             |

## 🛠 Quick Start

> [!IMPORTANT]
> This environment is designed to run in **VS Code Dev Containers**.

1.  **Launch**: Open folder in VS Code and click **"Reopen in Container"**.
2.  **Generate**: Run the publishing engine to build your architecture documents.
    ```bash
    python3 conversions/publish.py
    ```
3.  **Consume**: Find high-fidelity HTML and DOCX reports in `superapp/dist/`.

## 🧰 The Toolbox

| Category     | Tools & Technologies                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Cloud**    | ![Azure CLI](https://img.shields.io/badge/-Azure_CLI-%230089D6?style=flat-square&logo=microsoft-azure&logoColor=white) ![PowerShell](https://img.shields.io/badge/-PowerShell-%235391FE?style=flat-square&logo=powershell&logoColor=white) ![Bicep](https://img.shields.io/badge/-Bicep-%230078D4?style=flat-square&logo=microsoft-azure&logoColor=white) ![Terraform](https://img.shields.io/badge/-Terraform-%237B42BC?style=flat-square&logo=terraform&logoColor=white) |
| **Docs**     | ![Pandoc](https://img.shields.io/badge/-Pandoc-%23E1523D?style=flat-square&logo=pandoc&logoColor=white) ![Mermaid](https://img.shields.io/badge/-Mermaid-%23FF3670?style=flat-square&logo=mermaid&logoColor=white) ![Markdown](https://img.shields.io/badge/-Markdown-%23000000?style=flat-square&logo=markdown&logoColor=white)                                                                                                                                           |
| **Logic**    | ![Python](https://img.shields.io/badge/-Python_3.13-%233776AB?style=flat-square&logo=python&logoColor=white) ![uv](https://img.shields.io/badge/-uv-%23000000?style=flat-square&logo=python&logoColor=white) ![Node.js](https://img.shields.io/badge/-Node.js_22-%23339933?style=flat-square&logo=node.js&logoColor=white)                                                                                                                                                 |
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

Ubuntu 24.04 based container pre-baked with:

- **Optimization**: Multi-architecture support for x64 and ARM64.
- **Automation**: GitHub CLI (`gh`) and Azure CLI Extensions pre-installed.
- **Stability**: Fixed package versions for reproducible builds.
</details>

---

<p align="center">
  <img src="https://img.shields.io/badge/Powered_by-GitHub_Copilot-000000?style=for-the-badge&logo=github&logoColor=white" />
  <img src="https://img.shields.io/badge/Maintained_for-Azure_Architects-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white" />
</p>

<p align="center">
  <i>Built with ⚡ for High-Performance Azure Architecture</i>
</p>
