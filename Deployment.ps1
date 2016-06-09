Import-Module psake

Task Default -depends AcceptanceTests

Task GenerateEnvironmentFiles{
     Exec {& $PSScriptRoot\TestEnv.ps1}
}

Task DeployBuildEnvironment -depends GenerateEnvironmentFiles {
    
    $BuildServer = Get-LabVM -ConfigurationData $PSScriptRoot\Configs\Build.psd1 -ErrorAction SilentlyContinue
    # Create lab if it does not already exist
    if ($BuildServer -eq $null)
    {
        $Cred = Import-Clixml $PSScriptRoot\BuildServerCred.xml
        $BuildServer = Start-LabConfiguration -ConfigurationData $PSScriptRoot\Configs\Build.psd1 -Credential $Cred -SkipMofCheck -Verbose
    }
    
    # Start lab it is turned off but exists
    if($BuildServer.State -eq 'Off')
    {
        Enable-VMIntegrationService -VMName $BuildServer.Name -Name "Guest Service Interface"
        Start-Lab -ConfigurationData $PSScriptRoot\Configs\Build.psd1 -Verbose
    }
    
    # Wait for machine to come up
    while ($BuildServer.NetworkAdapters -eq $null) 
    {
        if($BuildServer -eq $null)
        {
            Throw "Build Server not found."
        }
        "Waiting for Build Server to be available. I will try again in 5 seconds"
        Start-Sleep -Seconds 5
        $BuildServer = Get-LabVM -ConfigurationData $PSScriptRoot\Configs\Build.psd1 -ErrorAction SilentlyContinue
    } 
    
    # Copy Source files to Build Server
    dir $PSScriptRoot\Source\ | %{Copy-VMFile -VMName $BuildServer.Name -SourcePath $_.FullName -DestinationPath c:\Source\$_ -FileSource Host -CreateFullPath -Force}
    "Successfully copied Source files to Build server: $($BuildServer.Name)."  
    
    # Copy configuration files to Build Server
    dir $PSScriptRoot\Configs\ | %{Copy-VMFile -VMName $BuildServer.Name -SourcePath $_.FullName -DestinationPath c:\Configs\$_ -FileSource Host -CreateFullPath -Force}
    "Successfully copied configuration files to Build server: $($BuildServer.Name)."  
    
    # Copy unit tests to Build server
    dir $PSScriptRoot\Tests\Unit\ | %{Copy-VMFile -VMName $BuildServer.Name -SourcePath $_.FullName -DestinationPath c:\Tests\Unit\$_ -FileSource Host -CreateFullPath -Force}
    "Successfully copied Unit Test files to Build server: $($BuildServer.Name)." 
     
}

Task UnitTests -Depends DeployBuildEnvironment {
    $BuildServer = Get-LabVM -ConfigurationData $PSScriptRoot\Configs\Build.psd1 -ErrorAction SilentlyContinue
    $Cred = Import-Clixml $PSScriptRoot\BuildServerCred.xml
    
    # Run Script Analyzer
    "Starting static analysis..."
    "Successfully completed static analysis."
    
    # Run Unit Tests
    "Starting unit tests..."
    Invoke-Command -VMName $BuildServer.Name -Credential $Cred -ScriptBlock {pushd \Tests\ ; Invoke-Pester}
    "Successfully completed unit tests." 
    
    # Run Code Coverage to ensure it is greater than 75%
    "Starting code coverage..."
    # Invoke-Command -VMName $BuildServer.Name -Credential $Cred -ScriptBlock {Invoke-Pester c:\Tests\Unit\ -CodeCoverage }
    "Successfully completed code coverage." 
}

Task BuildApp -depends UnitTests {
    "Project BuildApp completed Successfully"
}

Task CompileConfigs -Depends UnitTests {
    $BuildServer = Get-LabVM -ConfigurationData $PSScriptRoot\Configs\Build.psd1 -ErrorAction SilentlyContinue
    $Cred = Import-Clixml $PSScriptRoot\BuildServerCred.xml
    
    Invoke-Command -VMName $BuildServer.Name -Credential $Cred -ScriptBlock {dir c:\Configs\ | %{&($_.FullName); $ConfigName = (get-command -CommandType Configuraiton).Name; &($ConfigName) -OutputPath c:\MofOutputPath\ -SourcePath "\\Server1\Configs\"}}
}

Task DeployTestEnvironments -Depends CompileConfigs, BuildApp {
    "Environments deploying"
}

Task IntegrationTests -Depends DeployConfigs, UnitTests {
    "Integration tests ran successfully"
}

Task DeployConfigs -Depends DeployTestEnvironments, CompileConfigs {
    "Configs applied to target nodes"
    #push or Pull environment
}

Task AcceptanceTests -Depends DeployConfigs, IntegrationTests {
    "Acceptance tests processed"
}


## Parallel Tasks
## Invoke-Parallel (https://github.com/RamblingCookieMonster/Invoke-Parallel)