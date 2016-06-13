####################################################################
# Integration tests for WebsiteConfig
#
# Integration tests:  Website is configured as intended.
####################################################################

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Verbose $here
$parent = Split-Path -Parent $here
Write-Verbose $parent
$configPath = Join-Path $parent "Configs"
Write-Verbose $configPath
$sut = ($MyInvocation.MyCommand.ToString()) -Replace ".Tests.", "."
Write-Verbose $sut
. $(Join-Path $configPath $sut)

if (! (Get-Module xWebAdministration -ListAvailable))
{
    Install-Module -Name xWebAdministration -Force
}

Describe "Website configuration" {
    It Should "Initial do nothing test." {
        $true | should be $true
    }
}