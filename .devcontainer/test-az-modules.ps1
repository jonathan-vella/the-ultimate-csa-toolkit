$ErrorActionPreference = 'Stop'
$Expected = @{
    'Az.Accounts' = '5.5.3'
    'Az.Resources' = '10.2.1'
    'Az.Storage' = '9.7.2'
    'Az.Network' = '8.3.0'
    'Az.KeyVault' = '6.6.1'
    'Az.Websites' = '4.2.0'
}

function Assert-True($Condition, $Message) {
    if (-not $Condition) { throw $Message }
}

function Register-PSRepository {
    param($Name, $SourceLocation, $InstallationPolicy, $ErrorAction)
    Assert-True ($Name -like 'csa-build-*') 'Repository must be temporary.'
    Assert-True ($InstallationPolicy -eq 'Untrusted') 'Registration must not persist trust.'
    $script:SelectedUri = $SourceLocation
    if ($script:Scenario -eq 'register-failure') { throw 'Fixture registration failure' }
    $script:RegisteredName = $Name
}

function Install-Module {
    param($Name, $RequiredVersion, $Scope, $Repository, [switch]$Force, $ErrorAction)
    Assert-True ($Repository -eq $script:RegisteredName) 'Install used a different repository.'
    Assert-True ($RequiredVersion -eq $Expected[$Name]) 'Install changed a module pin.'
    Assert-True ($Scope -eq 'AllUsers') 'Install changed module scope.'
    Assert-True $Force.IsPresent 'Explicit install approval is required.'
    $script:Installed += $Name
    if ($script:Scenario -eq 'install-failure') { throw 'Fixture installation failure' }
}

function Import-Module {
    param($Name, $RequiredVersion, $ErrorAction)
    Assert-True ($RequiredVersion -eq $Expected[$Name]) 'Import changed a module pin.'
    $script:Imported += $Name
    if ($script:Scenario -eq 'import-failure') { throw 'Fixture import failure' }
}

function Unregister-PSRepository {
    param($Name, $ErrorAction)
    Assert-True ($Name -eq $script:RegisteredName) 'Cleanup used a different repository.'
    $script:Cleaned = $true
}

$Previous = $env:CSA_POWERSHELL_REPOSITORY_URL
try {
    foreach ($script:Scenario in @('default', 'custom', 'install-failure', 'import-failure', 'register-failure', 'invalid')) {
        $script:Installed = @()
        $script:Imported = @()
        $script:RegisteredName = $null
        $script:SelectedUri = $null
        $script:Cleaned = $false
        $env:CSA_POWERSHELL_REPOSITORY_URL = ''
        if ($script:Scenario -eq 'custom') {
            $env:CSA_POWERSHELL_REPOSITORY_URL = 'https://feeds.example.org/powershell/v2'
        }
        if ($script:Scenario -eq 'invalid') {
            $env:CSA_POWERSHELL_REPOSITORY_URL = 'https://user:secret@feeds.example.org/powershell/v2'
        }
        $Failed = $false
        try {
            . (Join-Path $PSScriptRoot 'install-az-modules.ps1')
        }
        catch {
            $Failed = $true
            Assert-True ($_.Exception.Message -notmatch 'secret') 'Failure exposed source credentials.'
        }
        if ($script:Scenario -in @('default', 'custom')) {
            Assert-True (-not $Failed) "Unexpected failure: $script:Scenario"
            Assert-True ($script:Installed.Count -eq 6 -and $script:Imported.Count -eq 6) 'All six modules must install and import.'
        }
        else {
            Assert-True $Failed "Failure was hidden: $script:Scenario"
        }
        if ($script:Scenario -eq 'invalid') {
            Assert-True (-not $script:SelectedUri) 'Invalid source reached repository registration.'
        }
        elseif ($script:Scenario -eq 'custom') {
            Assert-True ($script:SelectedUri -eq $env:CSA_POWERSHELL_REPOSITORY_URL) 'Custom source was not used.'
        }
        else {
            Assert-True ($script:SelectedUri -eq 'https://packagefeedproxy.microsoft.io/powershell/v2') 'Default source was not CFS.'
        }
        Assert-True ($script:Cleaned -eq ($script:Scenario -notin @('register-failure', 'invalid'))) 'Temporary repository cleanup was incorrect.'
    }
    Write-Output 'PowerShell feed tests passed (six scenarios; no packages installed).'
}
finally {
    $env:CSA_POWERSHELL_REPOSITORY_URL = $Previous
}
