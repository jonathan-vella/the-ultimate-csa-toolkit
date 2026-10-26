# Windows to Azure Linux WSL bootstrap

This is a small **evaluation/development** setup, not a WSL version of the Dockerfile.
Azure Linux 4 is a **preview**, not a production recommendation. The latest-release
implementation completed a core run and rerun on an existing native x64 WSL
distribution on 2026-10-26. Fresh installation, ARM64 and live dotfiles remain
unvalidated.

## Run next time

From the existing toolkit checkout in **Windows PowerShell 7.4+**, choose your
Linux account explicitly:

```powershell
pwsh -NoProfile -File .\.devcontainer\wsl\bootstrap.ps1 -LinuxUser jonathan
```

The account is reused if it exists (UID >=1000, existing absolute home); otherwise
it is created with `/bin/bash` and a locked password. Existing Unix account
metadata is not changed. The chosen account becomes AzureLinux-4's default user
only after core checks pass. No password or passwordless sudo rule is created.
If needed, set a password explicitly from a root session:
`wsl -d AzureLinux-4 -u root -- passwd jonathan`.

Prerequisites:

- Native Windows x64 or ARM64, hardware virtualization and functioning **WSL 2**.
  This script requires WSL **2.6.0+** for modern `.wsl` installation and user
  management. If missing, explicitly run `wsl --install --no-distribution` in an
  elevated Windows terminal; update older WSL with `wsl --update`. Complete any
  Windows elevation/reboot prompts yourself, then rerun the bootstrap.
- `wsl --status` must work. Pending Windows servicing/update reboots stop the
  bootstrap. It never enables Windows features, self-elevates or restarts Windows.
- HTTPS access to Microsoft's official image/package services, GitHub releases,
  unauthenticated `api.github.com`, `raw.githubusercontent.com`, `cli.github.com`
  and Azure Linux native repositories. Every run resolves release metadata over
  the network; rate limits, missing asset digests and network failures stop it.
  No npm/pip packages are installed; CFS language-package routing is unchanged.
- For a **fresh** distro install, GnuPG on Windows (`gpg.exe` on PATH, or the
  copy in `C:\Program Files\Git\usr\bin`). It verifies Microsoft's current image
  checksum signature in an isolated temporary keyring, not a personal keyring.
  The script never installs GnuPG itself. Existing distros do not require it.
- Enough disk space for the WSL package and distribution. Downloaded images are
  temporary and removed after the installation attempt.

## What it changes

The bootstrap downloads Microsoft's architecture-matched `.wsl` package **only if
AzureLinux-4 is absent**, verifies the current signed Microsoft checksum, and installs it without
launching interactive setup. It verifies WSL 2, Azure Linux 4.0, native architecture
and systemd as PID 1 before provisioning. An existing WSL 1 distro is not converted
automatically: review/back up first, then explicitly use
`wsl --set-version AzureLinux-4 2` and rerun.

Inside **only AzureLinux-4**, it installs:

- Latest available native `azure-cli` from Azure Linux's existing Microsoft
  repository; `gh` from the official GitHub CLI RPM repository using DNF5 with
  refreshed metadata, targeted upgrades and package signature checks.
- Git, jq, curl, unzip, tar/gzip, libicu and the account/session utilities.
- Latest stable standalone Copilot CLI and Bicep binaries from their official
  GitHub `/releases/latest` endpoints, rejecting drafts/prereleases. The exact
  architecture-matched release assets must have official SHA-256 digests.
  Downloads are checked against those digests **before** extraction or execution.
  No version/checksum pins or dev-container installation manifests are used.

Both provisioning phases start with a clean Linux environment and native-only
PATH, not inherited Windows tools or credentials. The selected Linux user's Azure
CLI configuration is set to use Bicep from PATH, disable its Bicep version check,
and disable Azure CLI self-upgrades. `/usr/local/bin/bicep` is the chosen binary
for both `bicep` and `az bicep` in a normal native Linux PATH. If your own shell
customizations override PATH, keep `/usr/local/bin` before other Bicep installs.
The bootstrap checks native CLI versions and timer activation, then selects the
default Linux user and sets **AzureLinux-4** as the default WSL distribution.

Existing Ubuntu/Docker distributions are not provisioned, stopped, converted or
removed. Existing distro/user configuration is otherwise retained, including
`/etc/wsl.conf` apart from the selected default user; systemd-disabled images stop
with a manual prerequisite message.
To enable it yourself, preserve that file's other sections, set `[boot]`
`systemd=true`, then exit sessions and explicitly restart **only AzureLinux-4**
with `wsl --terminate AzureLinux-4`. The bootstrap never runs a global WSL shutdown.

## Human sign-ins and resumable dotfiles

Open the selected Linux account:

```powershell
wsl -d AzureLinux-4 -u jonathan
```

In that Linux shell, perform the sign-ins you need:

```bash
gh auth login --hostname github.com
az login
copilot
```

Use Copilot's interactive sign-in flow. No Windows credential cache, tokens,
passwords or browser sessions are copied. Sign-ins are not asserted as complete
by the core setup message.

After Linux GitHub authentication, opt in to applying the private dotfiles:

```powershell
pwsh -NoProfile -File .\.devcontainer\wsl\bootstrap.ps1 -LinuxUser jonathan -ApplyDotfiles
```

The helper checks Linux `gh auth status` as that user, clones
`jonathan-vella/dotfiles` **main** to `~/dotfiles`, and runs its Linux `install.sh`
as the selected user, not root. File preservation/backups are delegated to that
repository's installer. This is execution of trusted personal configuration, not
a pinned toolkit dependency; review its main branch before opting in.

An existing checkout must have the expected HTTPS origin, be clean and on main.
Only a fast-forward pull is allowed: there is no reset, stash, deletion or branch
switch. Diverged checkouts or installer errors stop explicitly for manual action.
Missing/expired authentication returns helper status **20**, which Windows reports
as a failed/pending step with the sign-in/resume command, not full completion.
Core setup remains in place. Rerun the same command after resolving the issue.

Reruns reuse the distro/user, resolve current stable standalone versions, upgrade
the named RPMs and reconcile settings. A newer prerelease/custom standalone
installation can be replaced by the current stable release. Reruns do not rebuild
the distro. This rolling setup is not an immutable OS snapshot. The dev-container's
reviewed version/age policy remains unchanged; the WSL bootstrap intentionally
uses latest stable without a seven-day delay, as requested.

## Weekly updates

`dnf5-plugin-automatic` is enabled with `/etc/dnf/automatic.conf` settings:

```ini
[commands]
apply_updates=yes
upgrade_type=default
reboot=never
```

Unrelated settings remain; the first existing configuration is saved alongside it
with `.csa-before-bootstrap`. The managed timer drop-in is
`/etc/systemd/system/dnf5-automatic.timer.d/weekly.conf`:

```ini
[Timer]
OnCalendar=
OnCalendar=Sun *-*-* 06:00:00
Persistent=true
```

This clears the vendor calendar and selects **Sunday 06:00 in the distro's local
time zone**. The vendor timer retains its random delay of up to one hour. WSL must
be running; it is not woken by a Windows scheduled task. Persistent missed runs
catch up when the distro starts. Enabling the timer can trigger a due catch-up
immediately. Updates never automatically reboot. Inspect failures with
`systemctl status dnf5-automatic.service` and
`journalctl -u dnf5-automatic.service`. Review other administrator timer drop-ins
with `systemctl cat dnf5-automatic.timer` if its effective schedule differs.

DNF covers RPM packages, including Azure CLI and GitHub CLI. **It does not upgrade
standalone Copilot or Bicep.** There is no additional updater/timer here; rerun the
bootstrap to resolve their latest stable releases. Copilot's own product-managed
updates/cache are separate from DNF. The bootstrap's version check temporarily
uses `COPILOT_AUTO_UPDATE=false` to inspect the installed binary's bundled version,
not a newer user-cached package. It does not disable the user's normal Copilot
auto-update settings.

## Download verification and safe checks

Fresh installation follows Microsoft's current
[WSL checksum/signature procedure](https://github.com/microsoft/azurelinux/blob/4.0/docs/verify-wsl-signature-and-checksum.md).
It downloads architecture-specific checksum/signature files from the official
`https://aka.ms/azurelinux-4.0-{x86_64,aarch64}-wsl-checksum` and
`...-wsl-checksum-signature` URLs. It retrieves the Azure Linux 4 signing key from
Microsoft's `4.0` branch and requires its trusted identity:
`2BC9 4FFF 7015 A5F2 8F15 37AD 0CD9 FED3 3135 CE90`.
This fingerprint is a trust anchor, **not a version or checksum pin**. Key
rotation fails closed until that identity is independently reviewed and updated.
GPG must report a valid signature by this exact key before the manifest is parsed.
Only the entry matching the current architecture's package is accepted. Then the
current official `.wsl` package must match that signed SHA-256 before installation.
Publishing races between the manifest/image fail closed; retry later.

Standalone release metadata uses unauthenticated official GitHub HTTPS APIs and
asset digests, not a checksum sourced from arbitrary user input. No GitHub token,
Windows credential cache, authenticated download headers or remote install script
is used. Linux downloads disable curl configuration-file loading as well as using
the clean provisioning environment. Existing CLI credentials are used only by the separately requested
Linux dotfiles step, never for distribution or binary downloads.

Safe checks, from the repository root (PowerShell 7.4+ and Git Bash, or Bash on
a separate Linux test machine):

```powershell
pwsh -NoProfile -File .\.devcontainer\wsl\test-bootstrap.ps1
& 'C:\Program Files\Git\bin\bash.exe' --noprofile --norc -c 'bash -n .devcontainer/wsl/provision.sh && bash -n .devcontainer/wsl/test-provision.sh && bash .devcontainer/wsl/test-provision.sh'
```

These use temporary fixtures and mocked WSL, release APIs, GPG and authentication:
stable-release/digest/URL rejection, signer identity, image checksum and architecture
matching, UTF-16 WSL output handling, Bash stdin dispatch, existing/new distro
orchestration, no default changes after core failure, WSL 1 rejection,
auth-pending/resume, and idempotent configuration preservation. They **do not**
invoke WSL, install RPMs, authenticate or run the private installer.

The unauthenticated official release API resolution for both architectures and
actual Microsoft checksum signatures for both image architectures were also
checked from Windows, using temporary keyrings. That verifies metadata/signatures,
not installation or native binary compatibility.

Real validation on existing native x64 AzureLinux-4 as `jonathan` completed the
latest-release core bootstrap twice on 2026-10-26. Both runs verified official
binary hashes; Azure CLI 2.91.0, GitHub CLI 2.103.2 and Bicep 0.48.1 stayed unchanged.
Copilot's installed bundled version changed from the earlier 1.0.98 to current
stable 1.0.103 (normal launches already selected a cached 1.0.103).

Native executable paths, both Bicep version entry points, default AzureLinux-4
and user `jonathan` were confirmed. The effective timer was enabled/active with
Sunday 06:00 local time, persistence and the vendor's one-hour random delay.
Account metadata, existing shell/Git profile hashes, WSL configuration, named Azure
configuration, DNF/timer configuration and installed binary hashes were identical
across the rerun. Ubuntu-26.04 and docker-desktop remained registered and running.
No dotfiles installer, global WSL shutdown or distro recreation was performed.

These checks do not establish fresh `.wsl` installation, ARM64 execution, live
dotfiles, interactive cloud authentication, Azure deployment or a future unattended
timer firing. The full dev-container inventory, Docker/VS Code installation,
Windows tasks, Azure resources and production hardening remain out of scope.
