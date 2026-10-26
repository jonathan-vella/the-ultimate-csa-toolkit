#Requires -Version 7.4
# No Pester dependency: every WSL invocation and network download is mocked.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\bootstrap.ps1" -LinuxUser tester

function Assert-True($Condition, $Message) {
    if (-not $Condition) { throw $Message }
}
function Assert-Throws([scriptblock]$Action, [string]$Pattern) {
    try { & $Action } catch {
        Assert-True ($_.Exception.Message -match $Pattern) "Unexpected error: $_"
        return
    }
    throw "Expected failure matching: $Pattern"
}

$testDirectory = Join-Path ([IO.Path]::GetTempPath()) ("csa-wsl-tests-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $testDirectory | Out-Null
try {
    $Wsl = (Get-Process -Id $PID).Path
    Assert-Throws { Invoke-Wsl -Arguments @('-NoProfile', '-Command', 'exit 20') } 'exit 20'
    Invoke-Wsl -Arguments @('-NoProfile', '-Command',
        '$text = [Console]::In.ReadToEnd(); if ($text -cne "one`ntwo`n") { exit 17 }') -InputText "one`r`ntwo`r`n"
    Assert-Throws { Invoke-Wsl -Arguments @('-NoProfile', '-Command', 'exit 20') -InputText '' } 'exit 20'
    # Exercise the actual hash gate with a fake network response, never a real image.
    function Invoke-WebRequest {
        param($Uri, $OutFile)
        [IO.File]::WriteAllText($OutFile, 'not an official image')
    }
    Assert-Throws { Get-VerifiedImage ([pscustomobject]@{
        imageUrl = 'https://example.invalid/image.wsl'; imageSha256 = ('0' * 64)
    }) } 'checksum mismatch'

    function Assert-Prerequisites {}
    $script:testArchitecture = 'x64'
    function Get-HostArchitecture { $script:testArchitecture }
    function Get-VerifiedImage {
        param($Download)
        $directory = Join-Path $testDirectory 'download'
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        $package = Join-Path $directory 'fake.wsl'
        [IO.File]::WriteAllText($package, 'fixture')
        return $package
    }
    $script:calls = [Collections.Generic.List[object]]::new()
    $script:existing = $true
    $script:failSystem = $false
    $script:failDotfiles = $false
    $script:wslVersion = 2
    function Invoke-Wsl {
        param([string[]]$Arguments, [string]$InputText)
        $script:calls.Add($Arguments)
        switch ($Arguments[0]) {
            '--list' {
                if ($Arguments[1] -eq '--quiet') {
                    if ($script:existing) { "AzureLinux-4`0"; 'Ubuntu'; 'docker-desktop' }
                } else { "* AzureLinux-4 Running $script:wslVersion" }
            }
            '-d' {
                Assert-True ($Arguments[5] -eq '/usr/bin/env' -and $Arguments[6] -eq '-i') 'Linux must start with a clean environment.'
                Assert-True ($InputText -match 'provision_system') 'Expected the real helper as stdin.'
                if ('system' -in $Arguments -and $script:failSystem) { throw 'Mock system failure' }
                if ('dotfiles' -in $Arguments -and $script:failDotfiles) { throw 'Mock auth pending exit 20' }
            }
        }
    }

    Invoke-Bootstrap
    Assert-True (@($calls | Where-Object { $_[0] -eq '--install' }).Count -eq 0) 'Existing distro must not be reinstalled.'
    Assert-True ($calls[-1][0] -eq '--set-default') 'Default must follow verification.'
    Assert-True (@($calls | Where-Object { 'dotfiles' -in $_ }).Count -eq 0) 'Dotfiles must be opt-in.'

    $calls.Clear()
    $script:existing = $false
    Invoke-Bootstrap
    Assert-True (@($calls | Where-Object { $_[0] -eq '--install' }).Count -eq 1) 'Missing distro must install exactly once.'
    Assert-True (-not (Test-Path (Join-Path $testDirectory 'download'))) 'Temporary image must be cleaned up.'

    $calls.Clear()
    $script:existing = $true
    $script:failSystem = $true
    Assert-Throws { Invoke-Bootstrap } 'Mock system failure'
    Assert-True (@($calls | Where-Object { $_[0] -in @('--manage', '--set-default') }).Count -eq 0) 'Failed verification must not change defaults.'

    $calls.Clear()
    $script:failSystem = $false
    $script:wslVersion = 1
    Assert-Throws { Invoke-Bootstrap } 'not WSL 2'
    Assert-True (@($calls | Where-Object { $_[0] -eq '-d' }).Count -eq 0) 'WSL 1 must not be provisioned.'

    $script:wslVersion = 2
    $ApplyDotfiles = $true
    $script:failDotfiles = $true
    Assert-Throws { Invoke-Bootstrap } 'auth pending'
    $script:failDotfiles = $false
    Invoke-Bootstrap
    $calls.Clear()
    $script:testArchitecture = 'arm64'
    Invoke-Bootstrap
    $systemCall = @($calls | Where-Object { 'system' -in $_ })[0]
    $testPins = Get-Content (Join-Path $PSScriptRoot 'downloads.json') -Raw | ConvertFrom-Json
    Assert-True ('arm64' -in $systemCall -and $testPins.arm64.copilotSha256 -in $systemCall) 'ARM64 must receive its own binary pins.'
    $LinuxUser = 'root'
    Assert-Throws { Invoke-Bootstrap } 'non-root'
    Assert-True (@($calls | Where-Object {
        $_[0] -in @('--unregister', '--shutdown', '--terminate', '--set-version')
    }).Count -eq 0) 'Bootstrap must never remove, stop, or convert existing distros.'
    Write-Host 'PASS: mocked Windows orchestration, checksum gate, rerun, failure and auth-resume paths.'
} finally {
    Remove-Item -LiteralPath $testDirectory -Recurse -Force
}
