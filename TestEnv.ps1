
Import-Module $PSScriptRoot\..\DscPipelineTools -Force

# Define Networking
$Networking = @(
    @{ NetworkName             = 'TestNet'
        SwitchType              = 'Internal';
        IPv4AddressAssignment   = 'Static';
        IPv4NetworkAddress      = '10.0.0.0';
        IPv4DefaultGateway      = '10.0.0.254';
        IPv4SubnetMask          = 24;
        IPv4DnsServerAddress    = '10.0.0.1';
    }
)

# Define Unit Test Environment
$UnitTestEnvironment = @{
    Name                        = 'Test';
    Roles = @(
        @{  Role                = 'Website';
            VMName              = 'WebServer';
            VMQuantity          = 2;
            VMProcessorCount    = 1;
            VMStartupMemory     = 1GB;
            VMMedia             = '2016TP4_x64_Standard_Core_EN';
            NetworkName         = 'TestNet';
        },
        @{  Role                = 'SQL';
            VMName              = 'SqlServer';
            VMQuantity          = 1;
            VMProcessorCount    = 2;
            VMStartupMemory     = 6GB;
            VMMedia             = '2016TP4_x64_Standard_Core_EN';
            NetworkName         = 'TestNet';
        }
    )
}

Return New-DscConfigurationDataDocument -RawEnvData $UnitTestEnvironment -OtherEnvData $Networking -OutputPath $PSScriptRoot\Configs