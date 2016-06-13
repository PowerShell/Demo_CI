####################################################################
# Acceptance tests for WebsiteConfig
#
# Acceptance tests:  Website is configured as intended.
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

Describe "HTTP" {
    TCPPort TestAgent2 80 PingSucceeded {Should Be $true}
    Http http:\\TestAgent2 StatusCode { Should Be 200}
}