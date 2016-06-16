
Import-Module psake

function Throw-TestFailure
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

    Throw $errorRecord
}

FormatTaskName "--------------- {0} ---------------"

Properties {
    $TestsPath = "$PSScriptRoot\Tests"
    $TestResultsPath = "$TestsPath\Results"
    $MofPath = "$PSScriptRoot\..\MOF\"
    $ConfigPath = "$PSScriptRoot\Configs"
}

Task Default -depends AcceptanceTests

Task GenerateEnvironmentFiles -Depends Clean {
     Exec {& $PSScriptRoot\TestEnv.ps1 -OutputPath $ConfigPath}
}

Task ScriptAnalysis -Depends GenerateEnvironmentFiles {
    # Run Script Analyzer
    "Starting static analysis..."
    Invoke-ScriptAnalyzer -Path $ConfigPath 
}

Task UnitTests -Depends ScriptAnalysis {
    # Run Unit Tests with Code Coverage
    "Starting unit tests..."

    $PesterResults = Invoke-Pester -path "$TestsPath\Unit\"  -CodeCoverage "$ConfigPath\*.ps1" -OutputFile "$TestResultsPath\UnitTest.xml" -OutputFormat NUnitXml -PassThru
    $Coverage = $PesterResults.CodeCoverage.NumberOfCommandsExecuted / $PesterResults.CodeCoverage.NumberOfCommandsAnalyzed
    # how do we pass coverage numbers to TFS?

    if($PesterResults.FailedCount) #If Pester fails any tests fail this task
    {
        Throw-TestFailure -TestType Unit -PesterResults $PesterResults
    }
    elseif($Coverage -lt 0)
    {
        Throw
    }
}

Task CompileConfigs -Depends UnitTests {
    # Compile Configurations
    "Starting to compile configuration..."
    . "$ConfigPath\DNSServer.ps1"

    DNSServer -ConfigurationData "$ConfigPath\TestEnv.psd1" -OutputPath $MofPath
}

Task DeployConfigs -Depends CompileConfigs {
    "Deploying configurations to target nodes..."
    Start-DscConfiguration -path $MofPath -Wait -Verbose
    #push or pull
}

Task IntegrationTests -Depends DeployConfigs, UnitTests {
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
        Throw-TestFailure -TestType Integration -PesterResults $PesterResults
    }
}

Task AcceptanceTests -Depends DeployConfigs, IntegrationTests {
    "Starting Acceptance tests..."
    #Set module path
    #Invoke-OperationValidation -Module Acceptance
    
    $PesterResults = Invoke-Pester -path "$TestsPath\Acceptance\" -OutputFile "$TestResultsPath\AcceptanceTest.xml" -OutputFormat NUnitXml -PassThru
    
    if($PesterResults.FailedCount) #If Pester fails any tests fail this task
    {
        Throw-TestFailure -TestType Acceptance -PesterResults $PesterResults
    }
}

Task Clean {
    #Remove mof output from previous runs
    Remove-Item "$MofPath\*.mof" -Verbose

    #Remove Test Results from previous runs
    Remove-Item "$TestResultsPath\*.xml" -Verbose

    #Remove ConfigData generated from previous runs
    Remove-Item "$ConfigsPath\*.psd1" -Verbose
}