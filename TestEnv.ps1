
Import-Module $PSScriptRoot\..\DscPipelineTools -Force


# Define Unit Test Environment
$UnitTestEnvironment = @{
    Name                        = 'Test';
    Roles = @(
        @{  Role                = 'Website';
            VMName              = 'TestAgent2';
        },
        @{  Role                = 'DNSServer';
            VMName              = 'TestAgent1';
        }
    )
}

Return New-DscConfigurationDataDocument -RawEnvData $UnitTestEnvironment -OutputPath $PSScriptRoot\Configs