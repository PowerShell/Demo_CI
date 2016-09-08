
Import-Module psake

function Invoke-TestFailure
{
    param(
        [parameter(Mandatory=$true)]
        [validateSet('Unit','Integration','Acceptance')]
        [string]$TestType,

        [parameter(Mandatory=$true)]
        $PesterResults
    )

    $errorID = if($TestType -eq 'Unit'){'UnitTestFailure'}elseif($TestType -eq 'Integration'){'InetegrationTestFailure'}else{'AcceptanceTestFailure'}
    $errorCategory = [System.Management.Automation.ErrorCategory]::LimitsExceeded
    $errorMessage = "$TestType Test Failed: $($PesterResults.FailedCount) tests failed out of $($PesterResults.TotalCount) total test."
    $exception = New-Object -TypeName System.SystemException -ArgumentList $errorMessage
    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception,$errorID, $errorCategory, $null

    Write-Output "##vso[task.logissue type=error]$errorMessage"
    Throw $errorRecord
}

FormatTaskName "--------------- {0} ---------------"

Properties {
    $TestsPath = "$PSScriptRoot\Tests"
    $TestResultsPath = "$TestsPath\Results"
    $ArtifactPath = "$PSScriptRoot\.."
    $ModuleArtifactPath = "$ArtifactPath\Modules"
    $MOFArtifactPath = "$ArtifactPath\MOF"
}

Task Default -depends AcceptanceTests, IntegrationTests

Task DeployModules -Depends Clean {
    # Copy resources from build agent to target node(s)
    # This task uses push to deploy resource modules to target nodes. This task could be used to package up and deploy resources to DSC pull server instead.
    "Deploying resources to target nodes..."

    $Session = New-PSSession -ComputerName TestAgent1

    $ModulePath = "$env:ProgramFiles\WindowsPowerShell\Modules\"
    $ModuleArtifacts = "$ModuleArtifactPath"

    copy-item $ModuleArtifacts $ModulePath -Recurse -Force -ToSession $Session
    
    Remove-PSSession $Session
}

Task DeployConfigs -Depends DeployModules {
    "Deploying configurations to target nodes..."
    #This task uses push to deploy configurations. This task could be used to package up and push configurations to pull server instead.
    Start-DscConfiguration -path "$MOFArtifactPath\DevEnv" -Wait -Verbose
}

Task IntegrationTests -Depends DeployConfigs {
    "Starting Integration tests..."
    #Run Integration tests on target node
    $Session = New-PSSession -ComputerName TestAgent1

    #Create a folder to store test script on remote node
    Invoke-Command -Session $Session -ScriptBlock { $null = new-item \Tests\ -ItemType Directory -Force }
    Copy-Item -Path "$TestsPath\Integration\*" -Destination "c:\Tests" -ToSession $Session -verbose
    
    #Run pester on remote node and collect results
    $PesterResults = Invoke-Command -Session $Session -ScriptBlock { Invoke-Pester -Path c:\Tests -OutputFile "c:\Tests\IntegrationTest.xml" -OutputFormat NUnitXml -PassThru } 
    
    #Get Results xml from remote node
    Copy-Item -path "c:\Tests\IntegrationTest.xml" -Destination "$TestResultsPath" -FromSession $Session #-ErrorAction Continue
    Invoke-Command -Session $Session -ScriptBlock {remove-Item "c:\Tests\" -Recurse} #-ErrorAction Continue

    if($PesterResults.FailedCount) #If Pester fails any tests fail this task
    {
        Invoke-TestFailure -TestType Integration -PesterResults $PesterResults
    }

    Remove-PSSession $Session
}

Task AcceptanceTests -Depends DeployConfigs, IntegrationTests {
    "Starting Acceptance tests..."
    #Set module path
    
    $PesterResults = Invoke-Pester -path "$TestsPath\Acceptance\" -OutputFile "$TestResultsPath\AcceptanceTest.xml" -OutputFormat NUnitXml -PassThru
    
    if($PesterResults.FailedCount) #If Pester fails any tests fail this task
    {
        Invoke-TestFailure -TestType Acceptance -PesterResults $PesterResults
    }
}

Task Clean {
    "Starting Cleaning enviroment..."
    try {
        #Make sure Test Result location exists
        New-Item $TestResultsPath -ItemType Directory -Force

        #Remove modules from target node
        $Session = New-PSSession -ComputerName TestAgent1
        $RequiredModules = @()
        dir $ModuleArtifactPath -Directory | %{$RequiredModules += @{Name="$($_.Name)";Version="$(dir $ModuleArtifactPath\$($_.Name))"}}

        foreach ($Resource in $RequiredModules)
        {
            $ModulePath = "$env:ProgramFiles\WindowsPowerShell\Modules\$($Resource.Name)\$($Resource.Version)\"
            
            Invoke-Command -ScriptBlock {if(Test-Path $using:ModulePath) {Remove-Item $using:ModulePath -Recurse -Force}} -Session $Session
            
        }
    }
    finally
    {
        Remove-PSSession $Session -ErrorAction Ignore
    }
    
    
}
