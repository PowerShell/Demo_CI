param(
    [parameter(Mandatory=$true)]
    [string]
    $OutputPath
)

# Import the function that creates the configuration data file
Import-Module $PSScriptRoot\..\Assets\DscPipelineTools\DscPipelineTools.psd1 -Force

# Define the data for the development environment
$DevEnvironment = @{
    Name                        = 'DevEnv';
    Roles = @(
        @{  Role                = 'DNSServer';
            VMName              = '13.78.178.187';
            Zone                = 'Contoso.com';
            ARecords            = @{'TFSSrv1'= '10.0.0.10';'Client'='10.0.0.15';'BuildAgent'='10.0.0.30';'TestAgent1'='10.0.0.40';'TestAgent2'='10.0.0.50'};
            CNameRecords        = @{'DNS' = 'TestAgent1.contoso.com'; 'www' = 'TestAgent2.contoso.com';};
        }
    )
}

# Create the configuration data file
Return New-DscConfigurationDataDocument -RawEnvData $DevEnvironment -OutputPath $OutputPath