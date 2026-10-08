$ErrorActionPreference = 'Stop'
$Modules = @{
    'Az.Accounts' = '5.5.3'
    'Az.Resources' = '10.2.1'
    'Az.Storage' = '9.7.2'
    'Az.Network' = '8.3.0'
    'Az.KeyVault' = '6.6.1'
    'Az.Websites' = '4.2.0'
}
foreach ($Name in $Modules.Keys) {
    Install-PSResource -Name $Name -Version $Modules[$Name] -Scope AllUsers -Repository PSGallery -TrustRepository
    Import-Module $Name -RequiredVersion $Modules[$Name] -ErrorAction Stop
}
