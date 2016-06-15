
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

Properties {
    $TestsPath = $PSScriptRoot\Tests
    $TestResultsPath = $TestsPath\Results
    $MofPath = $PSScriptRoot\..\MOF\
    $ConfigPath = $PSScriptRoot\Tests
    $ConfigData = $null #Override this!!
    $FirstTask = 'CompileConfigs' #AcceptanceTests
}

Task Default -depends $FirstTask

Task GenerateEnvironmentFiles{
     Exec {& $PSScriptRoot\TestEnv.ps1}
}

Task ScriptAnalysis -Depends GenerateEnvironmentFiles {
    
     # Run Script Analyzer
    "Starting static analysis..."
    Invoke-ScriptAnalyzer -Path $ConfigPath 
}

Task UnitTests -Depends ScriptAnalysis {
     # Run Unit Tests with Code Coverage
    "Starting unit tests..."

    $PesterResults = Invoke-Pester -path $TestsPath\Unit\  -CodeCoverage $ConfigPath\*.ps1 -OutputFile $TestResultsPath\UnitTest.xml -OutputFormat NUnitXml -PassThru
    $Coverage = $PesterResults.CodeCoverage.NumberOfCommandsExecuted / $PesterResults.CodeCoverage.NumberOfCommandsAnalyzed
    # how do we pass coverage numbers to TFS?

    if($PesterResults.FailedCount -gt 0)
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
    . $ConfigPath\DNSServer.ps1

    DNSServer -OutputPath $MofPath
}

Task DeployConfigs -Depends CompileConfigs {
    "Configs applied to target nodes"
    #push or Pull environment
}

Task IntegrationTests -Depends DeployConfigs, UnitTests {
    "Integration tests ran successfully"
}

Task AcceptanceTests -Depends DeployConfigs, IntegrationTests {
    "Acceptance tests processed"
}