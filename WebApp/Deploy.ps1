
Import-Module psake
Import-Module $PSScriptRoot\..\Assets\DscPipelineTools\DscPipelineTools.psd1 -Force

FormatTaskName "--------------- {0} ---------------"

Properties {
    $TestsPath = Join-Path $PSScriptRoot 'Tests'
    $TestResultsPath = Join-Path $TestsPath 'Results'
    $ArtifactPath = Join-Path $PSScriptRoot '..'
    $ModuleArtifactPath = Join-Path $ArtifactPath 'Modules'
    $MOFArtifactPath = Join-Path $ArtifactPath 'MOF'
}

Task Default -depends AcceptanceTests

Task DeployModules -Depends Clean {
    # Copy resources from build agent to target node(s)
    # This task uses push to deploy resource modules to target nodes. This task could be used to package up and deploy resources to DSC pull server instead.
    'Deploying resources to target nodes...'

    $Session = New-PSSession -ComputerName TestAgent1

    $ModulePath = "$(Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules')"
    $ModuleArtifacts = "$ModuleArtifactPath"

    copy-item $ModuleArtifacts $ModulePath -Recurse -Force -ToSession $Session
    
    Remove-PSSession $Session
}

Task DeployConfigs -Depends DeployModules {
    'Deploying configurations to target nodes...'
    #This task uses push to deploy configurations. This task could be used to package up and push configurations to pull server instead.
    Start-DscConfiguration -path "$(Join-Path $MOFArtifactPath 'DevEnv')" -Wait -Verbose
}

Task IntegrationTests -Depends DeployConfigs {
    'Starting Integration tests...'
    #Run Integration tests on target node
    $Session = New-PSSession -ComputerName TestAgent1

    #Create a folder to store test script on remote node
    Invoke-Command -Session $Session -ScriptBlock { $null = new-item \Tests\ -ItemType Directory -Force }
    Copy-Item -Path "$(Join-Path $TestsPath 'Integration\*')" -Destination 'c:\Tests' -ToSession $Session -verbose
    
    #Run pester on remote node and collect results
    $PesterResults = Invoke-Command -Session $Session `
        -ScriptBlock { Invoke-Pester -Path 'c:\Tests' -OutputFile 'c:\Tests\IntegrationTest.xml' -OutputFormat NUnitXml -PassThru } 
    
    #Get Results xml from remote node
    Copy-Item -path 'c:\Tests\IntegrationTest.xml' -Destination "$TestResultsPath" -FromSession $Session 
    Invoke-Command -Session $Session -ScriptBlock {remove-Item 'c:\Tests\' -Recurse} 

    New-TestValidation -TestType Integration -PesterResults $PesterResults

    Remove-PSSession $Session
}

Task AcceptanceTests -Depends DeployConfigs, IntegrationTests {
    'Starting Acceptance tests...'
    #Set module path
    
    $PesterResults = Invoke-Pester -path "$(Join-Path $TestsPath 'Acceptance')" `
                                   -OutputFile "$(Join-Path $TestResultsPath 'AcceptanceTest.xml')" `
                                   -OutputFormat NUnitXml `
                                   -PassThru
    

    New-TestValidation -TestType Acceptance -PesterResults $PesterResults
    
}

Task Clean {
    'Starting Cleaning enviroment...'
    try {
        #Make sure Test Result location exists
        New-Item $TestResultsPath -ItemType Directory -Force

        #Remove modules from target node
        $Session = New-PSSession -ComputerName TestAgent1
        $RequiredModules = @()
        dir $ModuleArtifactPath -Directory | %{$RequiredModules += `
                    @{Name="$($_.Name)";Version="$(dir $ModuleArtifactPath\$($_.Name))"}}

        foreach ($Resource in $RequiredModules)
        {
            $ModulePath = "Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules'"
            $ModulePath = "Join-Path $ModulePath $($Resource.Name)"
            $ModulePath = "Join-Path $ModulePath $($Resource.Version)"
            
            Invoke-Command -ScriptBlock {if(Test-Path $using:ModulePath) {Remove-Item $using:ModulePath -Recurse -Force}} `
                           -Session $Session
        }
    }
    finally
    {
        Remove-PSSession $Session -ErrorAction Ignore
    }
    
    
}