param(
    [parameter(Mandatory=$true)]
    [string]
    $OutputPath
)

Import-Module $PSScriptRoot\..\Assets\DscPipelineTools\DscPipelineTools.psd1 -Force

# Define Unit Test Environment
$DevEnvironment = @{
    Name                        = 'DevEnv'
    Roles = @(
        @{  Role                = 'WebServer'
            VMName              = 'TestAgent1'
            Zone                = 'Contoso.com'
        }
    )
}

New-DscConfigurationDataDocument -RawEnvData $DevEnvironment -OutputPath $OutputPath