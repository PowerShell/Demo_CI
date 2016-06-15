
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

Task Default -depends DeployConfigs

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
    . "$ConfigPath\DNSServer.ps1"

    DNSServer -ConfigurationData "$ConfigPath\TestEnv.psd1" -OutputPath $MofPath
}

Task DeployConfigs -Depends CompileConfigs {
    "Deploying configurations to target nodes..."
    Start-DscConfiguration -path $MofPath -Wait -Verbose
}

Task IntegrationTests -Depends DeployConfigs, UnitTests {
    "Integration tests ran successfully"
}

Task AcceptanceTests -Depends DeployConfigs, IntegrationTests {
    "Acceptance tests processed"
}

Task Clean {
    #Remove mof output from previous runs
    Remove-Item "$MofPath\*.mof" -Verbose

    #Remove Test Results from previous runs
    Remove-Item "$TestResultsPath\*.xml" -Verbose

    #Remove ConfigData generated from previous runs
    Remove-Item "$ConfigsPath\*.psd1" -Verbose
}