#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z_][a-z0-9_-]{0,31}$')]
    [string]$LinuxUser,
    [switch]$ApplyDotfiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Distro = 'AzureLinux-4'
$Wsl = "$env:WINDIR\System32\wsl.exe"

function Invoke-Wsl {
    param([string[]]$Arguments, [string]$InputText)
    if ($PSBoundParameters.ContainsKey('InputText')) {
        # Write exact UTF-8/LF bytes; PowerShell's text pipeline appends CRLF on Windows.
        $start = [Diagnostics.ProcessStartInfo]::new($Wsl)
        $start.UseShellExecute = $false
        $start.RedirectStandardInput = $true
        $start.StandardInputEncoding = [Text.UTF8Encoding]::new($false)
        foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
        $process = [Diagnostics.Process]::Start($start)
        try {
            $process.StandardInput.Write($InputText.Replace("`r`n", "`n"))
            $process.StandardInput.Close()
            $process.WaitForExit()
            $exitCode = $process.ExitCode
        } finally {
            $process.Dispose()
        }
    } else {
        & $Wsl @Arguments
        $exitCode = $LASTEXITCODE
    }
    if ($exitCode -ne 0) {
        throw "WSL failed (exit $exitCode): $($Arguments -join ' '). Resolve the error and rerun."
    }
}

function Assert-Prerequisites {
    if (-not $IsWindows) { throw 'Run this entry point in Windows PowerShell 7.4 or newer.' }
    if (-not (Test-Path $Wsl)) {
        throw 'WSL is missing. In an elevated Windows terminal run: wsl --install --no-distribution. Reboot when requested, then rerun.'
    }
    foreach ($key in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    )) {
        if (Test-Path $key) { throw 'Windows reports a pending reboot. Reboot explicitly, then rerun.' }
    }
    try {
        $versionOutput = (Invoke-Wsl -Arguments @('--version')) -join "`n"
    } catch {
        throw "Modern WSL is unavailable. Run wsl --update yourself (or elevated wsl --install --no-distribution if missing), reboot if requested, then rerun. $_"
    }
    if ($versionOutput -notmatch '(\d+\.\d+\.\d+)(?:\.\d+)?' -or [version]$Matches[1] -lt [version]'2.6.0') {
        throw 'WSL 2.6.0+ is required. Run wsl --update yourself, reboot if requested, then rerun.'
    }
    try {
        Invoke-Wsl -Arguments @('--status') | Out-Host
    } catch {
        throw "WSL is not ready. Resolve its prerequisite/virtualization error above and any requested elevation or reboot, then rerun. $_"
    }
}

function Get-HostArchitecture {
    switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()) {
        'X64' { return 'x64' }
        'Arm64' { return 'arm64' }
        default { throw 'Only native Windows x64 and ARM64 are supported.' }
    }
}

function Get-VerifiedImage {
    param($Download)
    $directory = Join-Path ([IO.Path]::GetTempPath()) ("csa-wsl-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $directory | Out-Null
    $package = Join-Path $directory 'AzureLinux-4.wsl'
    try {
        Invoke-WebRequest -Uri $Download.imageUrl -OutFile $package
        if ((Get-FileHash -Algorithm SHA256 $package).Hash -ne $Download.imageSha256) {
            throw 'WSL image checksum mismatch. No image was installed. Review official signed checksums before updating downloads.json.'
        }
        return $package
    } catch {
        Remove-Item -LiteralPath $directory -Recurse -Force
        throw
    }
}

function Invoke-Bootstrap {
    if ($LinuxUser -eq 'root') { throw 'Choose a non-root Linux user explicitly.' }
    Assert-Prerequisites
    $arch = Get-HostArchitecture
    $pins = Get-Content (Join-Path $PSScriptRoot 'downloads.json') -Raw | ConvertFrom-Json
    $download = $pins.$arch
    foreach ($hash in @($download.imageSha256, $download.copilotSha256)) {
        if ($hash -cnotmatch '^[a-f0-9]{64}$') { throw 'Invalid reviewed download checksum.' }
    }
    if ($pins.copilotVersion -cnotmatch '^\d+\.\d+\.\d+$' -or
        [datetimeoffset]$pins.copilotPublishedAt -gt [datetimeoffset]::UtcNow.AddDays(-7)) {
        throw 'Copilot pin must be a stable release older than seven days.'
    }
    $versions = Get-Content (Join-Path $PSScriptRoot '..\tool-versions.env')
    $bicepVersion = ($versions | Where-Object { $_ -cmatch '^BICEP_VERSION=\d+\.\d+\.\d+$' }) -replace '^BICEP_VERSION=', ''
    if (@($bicepVersion).Count -ne 1) { throw 'Missing or ambiguous shared Bicep version.' }
    $hashArch = if ($arch -eq 'x64') { 'amd64' } else { 'arm64' }
    $checksums = Get-Content (Join-Path $PSScriptRoot '..\releases.sha256')
    $bicepHash = ($checksums | Where-Object { $_ -cmatch "^[a-f0-9]{64}  bicep-$hashArch$" }) -replace ' .*$', ''
    if (@($bicepHash).Count -ne 1) { throw 'Missing or ambiguous shared Bicep checksum.' }
    $helper = Get-Content (Join-Path $PSScriptRoot 'provision.sh') -Raw
    $installed = @((Invoke-Wsl -Arguments @('--list', '--quiet')) |
        ForEach-Object { ($_ -replace "`0", '').Trim() })
    if ($Distro -notin $installed) {
        $package = Get-VerifiedImage $download
        try {
            Invoke-Wsl -Arguments @('--install', '--from-file', $package, '--name', $Distro, '--no-launch') | Out-Host
        } finally {
            Remove-Item -LiteralPath (Split-Path $package) -Recurse -Force
        }
    }
    $list = ((Invoke-Wsl -Arguments @('--list', '--verbose')) -join "`n") -replace "`0", ''
    if ($list -notmatch '(?m)^\s*\*?\s*AzureLinux-4\s+.+?\s+2\s*$') {
        throw 'AzureLinux-4 is not WSL 2. Convert it explicitly with wsl --set-version AzureLinux-4 2, then rerun.'
    }
    Invoke-Wsl -Arguments @('-d', $Distro, '-u', 'root', '--exec', '/usr/bin/env', '-i',
        'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', '/bin/bash', '-s', '--',
        'system', $LinuxUser, $arch, $bicepVersion, $bicepHash, $pins.copilotVersion, $download.copilotSha256) -InputText $helper | Out-Host
    Invoke-Wsl -Arguments @('--manage', $Distro, '--set-default-user', $LinuxUser) | Out-Host
    Invoke-Wsl -Arguments @('--set-default', $Distro) | Out-Host
    if ($ApplyDotfiles) {
        Invoke-Wsl -Arguments @('-d', $Distro, '-u', $LinuxUser, '--exec', '/usr/bin/env', '-i',
            'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', '/bin/bash', '-s', '--',
            'dotfiles', $LinuxUser) -InputText $helper | Out-Host
        Write-Host 'Core setup verified; dotfiles installer finished.'
    } else {
        Write-Host 'Core setup verified; sign-ins and optional dotfiles remain human/resume steps.'
    }
    Write-Host "Open: wsl -d $Distro -u $LinuxUser"
    Write-Host 'Sign in inside Linux: gh auth login --hostname github.com; az login; copilot'
    Write-Host 'Use -ApplyDotfiles on a rerun after GitHub sign-in. No cloud sign-in was automated.'
}

if ($MyInvocation.InvocationName -ne '.') { Invoke-Bootstrap }
