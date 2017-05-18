<#
.SYNOPSIS
    Basic build script to publish a module to a repo
.EXAMPLE
    VSTS.ps1 -ModuleName ExampleModule
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$APIKEY,
    [Parameter(Mandatory=$true)]
    [string]$ModuleName
)
# Setup build agent for PowerShellGet
$PowerShellGetUserFolder = New-Item "$env:userprofile\AppData\Local\Microsoft\Windows\PowerShell\PowerShellGet\" -ItemType Directory
$DownloadNuGet           = Invoke-WebRequest -URI 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile (Join-Path $PowerShellGetUserFolder 'NuGet.exe')
$InstallProvider         = Install-PackageProvider 'PowerShellGet' -Scope CurrentUser -Force
# Install helper modules
$HelperModules           = Install-Module -Name InvokeBuild,Pester,PSScriptAnalyzer -Scope CurrentUser -Force

Invoke-Build -APIKey $APIKEY -ModuleName $ModuleName