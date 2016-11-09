####################################################################
# Unit tests for DNSServer
#
# Unit tests content of DSC configuration as well as the MOF output.
####################################################################

#region
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Verbose $here
$parent = Split-Path -Parent $here
$GrandParent = Split-Path -Parent $parent
Write-Verbose $GrandParent
$configPath = Join-Path $GrandParent "Configs"
Write-Verbose $configPath
$sut = ($MyInvocation.MyCommand.ToString()) -replace ".Tests.","."
Write-Verbose $sut
. $(Join-Path -Path $configPath -ChildPath $sut)

#endregion

Describe "DNSServer Configuration" {
    Context "Configuration Script"{
        
        It "Should be a DSC configuration script" {
            (Get-Command DNSServer).CommandType | Should be "Configuration"
        }

        It "Should not be a DSC Meta-configuration" {
            (Get-Command DNSServer).IsMetaConfiguration | Should Not be $true
        }

        It "Should use the xDNSServer DSC resource" {
            (Get-Command DNSServer).Definition | Should Match "xDNSServer"
        }
    }

    Context "Node Configuration" {
        $OutputPath = "TestDrive:\"
        
        It "Should not be null" {
            "$configPath\DevEnv.psd1" | Should Exist
        }
        
        It "Should generate a single mof file." {
            DNSServer -ConfigurationData "$configPath\DevEnv.psd1" -OutputPath $OutputPath 
            (Get-ChildItem -Path $OutputPath -File -Filter "*.mof" -Recurse ).count | Should be 1
        }
        
        It "Should generate a mof file with the name 'TestAgent1'." {
            DNSServer -ConfigurationData "$configPath\DevEnv.psd1" -OutputPath $OutputPath 
            Join-Path $OutputPath "TestAgent1.mof" | Should Exist
        }
        
        It "Should generate a new version (2.0) mof document." {
            DNSServer -ConfigurationData "$configPath\DevEnv.psd1" -OutputPath $OutputPath 
            Join-Path $OutputPath "TestAgent1.mof" | Should Contain "Version=`"2.0.0`""
        }
        
        #Clean up TestDrive between each test
        AfterEach {
            Remove-Item TestDrive:\* -Recurse
        }

    }
}
