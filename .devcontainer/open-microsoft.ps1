<#
.SYNOPSIS
Opens this repository in a fresh host VS Code process with Microsoft CFS feeds.
.DESCRIPTION
Close all VS Code windows first. Requires only the host code command and supports
Windows PowerShell 5.1. Does not persist settings or bypass execution policy.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Sources = @{
    CSA_NPM_REGISTRY_HOST_PATH = 'packagefeedproxy.microsoft.io/npm/'
    CSA_PYPI_INDEX_HOST_PATH = 'packagefeedproxy.microsoft.io/pypi/simple/'
    CSA_POWERSHELL_REPOSITORY_URL = 'https://packagefeedproxy.microsoft.io/powershell/v2'
}
$Previous = @{}

try {
    $Code = Get-Command -Name code -CommandType Application -ErrorAction Stop | Select-Object -First 1
    foreach ($Name in $Sources.Keys) {
        $Previous[$Name] = [Environment]::GetEnvironmentVariable($Name, 'Process')
        [Environment]::SetEnvironmentVariable($Name, $Sources[$Name], 'Process')
    }
    Write-Output 'Fully exit all VS Code windows first; an existing process retains its previous environment.'
    Write-Output 'Opening the toolkit with Microsoft CFS sources for image builds and container setup.'
    & $Code.Source (Join-Path $PSScriptRoot '..')
    if ($LASTEXITCODE -ne 0) {
        throw "VS Code exited with code $LASTEXITCODE."
    }
}
catch {
    Write-Error "Microsoft host launcher failed: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
finally {
    foreach ($Name in $Previous.Keys) {
        [Environment]::SetEnvironmentVariable($Name, $Previous[$Name], 'Process')
    }
}
