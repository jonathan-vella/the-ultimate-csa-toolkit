$ErrorActionPreference = 'Stop'
$RepositoryUrl = $env:CSA_POWERSHELL_REPOSITORY_URL
if ([string]::IsNullOrEmpty($RepositoryUrl)) {
    $RepositoryUrl = 'https://packagefeedproxy.microsoft.io/powershell/v2'
}
$Uri = $null
if (-not [Uri]::TryCreate($RepositoryUrl, [UriKind]::Absolute, [ref]$Uri) -or
    $Uri.Scheme -ne 'https' -or $Uri.Port -ne 443 -or
    $Uri.UserInfo -or $Uri.Query -or $Uri.Fragment -or
    $RepositoryUrl -match '[\s\\$`"'']' -or
    $RepositoryUrl -match '/\.\.?(/|$)') {
    throw 'PowerShell feed must be an HTTPS host/path URL without credentials or query strings.'
}
$Modules = @{
    'Az.Accounts' = '5.5.3'
    'Az.Resources' = '10.2.1'
    'Az.Storage' = '9.7.2'
    'Az.Network' = '8.3.0'
    'Az.KeyVault' = '6.6.1'
    'Az.Websites' = '4.2.0'
}
$RepositoryName = "csa-build-$([Guid]::NewGuid().ToString('N'))"
$Registered = $false
try {
    # CFS v2 returns package content links; PSResourceGet's /package route is unsupported.
    Register-PSRepository -Name $RepositoryName -SourceLocation $RepositoryUrl -InstallationPolicy Untrusted -ErrorAction Stop
    $Registered = $true
    foreach ($Name in $Modules.Keys) {
        Install-Module -Name $Name -RequiredVersion $Modules[$Name] -Scope AllUsers -Repository $RepositoryName -Force -ErrorAction Stop
        Import-Module $Name -RequiredVersion $Modules[$Name] -ErrorAction Stop
    }
}
finally {
    if ($Registered) {
        Unregister-PSRepository -Name $RepositoryName -ErrorAction Stop
    }
}
