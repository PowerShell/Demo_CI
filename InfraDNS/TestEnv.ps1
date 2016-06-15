param(
    [parameter(Mandatory=$true)]
    [string]
    $OutputPath
)

Import-Module $PSScriptRoot\..\Assets\DscPipelineTools\DscPipelineTools.psd1 -Force


# Define Unit Test Environment
$UnitTestEnvironment = @{
    Name                        = 'TestEnv';
    Roles = @(
        @{  Role                = 'DNSServer';
            VMName              = 'TestAgent1';
        }
    )
}

Return New-DscConfigurationDataDocument -RawEnvData $UnitTestEnvironment -OutputPath $OutputPath