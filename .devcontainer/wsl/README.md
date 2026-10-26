# Windows to Azure Linux WSL bootstrap

This is a small **evaluation/development** setup, not a WSL version of the Dockerfile.
Azure Linux 4 is a **preview**, not a production recommendation. Neither native
x64 nor ARM64 provisioning has been validated by this bootstrap's isolated tests.

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
  `cli.github.com` and the Azure Linux native repositories. No npm/pip packages
  are installed; the repository's CFS language-package routing is unchanged.
- Enough disk space for the WSL package and distribution. Downloaded images are
  temporary and removed after the installation attempt.

## What it changes

The bootstrap downloads Microsoft's architecture-matched `.wsl` package **only if
AzureLinux-4 is absent**, verifies its tracked SHA-256, and installs it without
launching interactive setup. It verifies WSL 2, Azure Linux 4.0, native architecture
and systemd as PID 1 before provisioning. An existing WSL 1 distro is not converted
automatically: review/back up first, then explicitly use
`wsl --set-version AzureLinux-4 2` and rerun.

Inside **only AzureLinux-4**, it installs:

- Native `azure-cli` from Azure Linux's existing Microsoft repository; `gh` from
  the official GitHub CLI RPM repository using DNF5 with package signature checks.
- Git, jq, curl, unzip, tar/gzip, libicu and the account/session utilities.
- Reviewed standalone Copilot CLI and Bicep binaries, SHA-256 checked **before**
  extraction or execution. Bicep reuses `../tool-versions.env` and
  `../releases.sha256`; Copilot/image pins are in `downloads.json`.

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

Reruns reuse the distro/user, reapply the reviewed standalone binary pins, and
reconcile the named settings. They can therefore replace newer standalone binaries
with the reviewed versions. They do not rebuild the distro. DNF resolves available
native RPM versions rather than providing an immutable OS snapshot.

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
standalone Copilot or Bicep.** There is no additional updater/timer here; update
their reviewed pins and rerun when needed. Any Copilot product-managed update
behavior is separate from DNF and this bootstrap.

## Download review and safe checks

The image hashes were taken from Microsoft's published
`https://aka.ms/azurelinux-4.0-{x86_64,aarch64}-wsl-checksum` files on 2026-10-26.
Both checksum signatures were checked in an isolated keyring with the official
Azure Linux 4.0 RPM key (fingerprint
`2BC9 4FFF 7015 A5F2 8F15 37AD 0CD9 FED3 3135 CE90`), retrieved from
Microsoft's repository at commit `8a6c0b47dd8e117b1e04e5bd8afeb1d844f4decd`.
Key identity is anchored to Microsoft's HTTPS repository, not an existing personal
GPG trust database. Runtime uses the reviewed tracked hashes, not a freshly
downloaded checksum as its own trust anchor.

The official image URLs are mutable: a changed image fails the hash check rather
than silently installing. Follow Microsoft's
[WSL checksum/signature procedure](https://github.com/microsoft/azurelinux/blob/4.0/docs/verify-wsl-signature-and-checksum.md)
before updating both architecture pins. Azure Linux 4's preview image is the
intentional preview exception; standalone tools use stable releases older than
seven days. Review the newest eligible stable releases and their official hashes,
updating shared Bicep pins coherently with the dev-container build contract.
Copilot 1.0.98 was published on 2026-10-14; its two hashes are the official GitHub
release asset digests. No remote install script is piped to a shell.

Safe checks, from the repository root (PowerShell 7.4+ and Git Bash, or Bash on
a separate Linux test machine):

```powershell
pwsh -NoProfile -File .\.devcontainer\wsl\test-bootstrap.ps1
& 'C:\Program Files\Git\bin\bash.exe' --noprofile --norc -c 'bash -n .devcontainer/wsl/provision.sh && bash -n .devcontainer/wsl/test-provision.sh && bash .devcontainer/wsl/test-provision.sh'
```

These use temporary fixtures and mocked WSL, downloads and authentication:
checksum rejection, existing/new distro orchestration, no default changes after
core failure, WSL 1 rejection, auth-pending/resume, and idempotent configuration
preserving unrelated settings/backups. They **do not** invoke WSL, install RPMs,
authenticate, run the private installer, or prove real native provisioning.
Actual `.wsl` installation, RPM resolution/signatures, binary compatibility and
systemd operation still require a future explicitly authorized native x64/ARM64
provisioning run. The full dev-container inventory, Docker/VS Code installation,
Windows tasks, Azure resources and production hardening are out of scope.
