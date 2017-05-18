<#
.SYNOPSIS
    Basic build script to publish a module to a repo
.EXAMPLE
    VSTS.ps1 -ModuleName ExampleModule
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ModuleName,
    [int32]$Major       = 0,
    [int32]$Minor       = 1,
    [string]$Repository = 'PrivateFeed'
)
$UpdateManifest          = Update-ModuleManifest -Path $env:BUILD_SOURCESDIRECTORY\$ModuleName\$ModuleName.psd1 -ModuleVersion "$Major.$Minor.$env:BUILD_BUILDNUMBER"
$ModuleFolder            = New-Item "$env:userprofile\Documents\WindowsPowerShell\Modules\$ModuleName" -ItemType Directory
$CopyModule              = Copy-Item "$env:BUILD_SOURCESDIRECTORY\$ModuleName" $ModuleFolder -Recurse
$PowerShellGetUserFolder = New-Item "$env:userprofile\AppData\Local\Microsoft\Windows\PowerShell\PowerShellGet\" -ItemType Directory
$DownloadNuGet           = Invoke-WebRequest -URI 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile (Join-Path $PowerShellGetUserFolder 'NuGet.exe')
$InstallProvider         = Install-PackageProvider 'PowerShellGet' -Scope CurrentUser -Force

Register-PSRepository -Name $Repository -SourceLocation $env:SourceLocation -PublishLocation $env:PublishLocation
Publish-Module -Name 'ExampleModule' -NuGetApiKey $env:APIKEY -Repository $Repository