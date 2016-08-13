
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
    $ArtifactPath = "$Env:BUILD_ARTIFACTSTAGINGDIRECTORY"
    $ModuleArtifactPath = "$ArtifactPath\Modules"
    $MOFArtifactPath = "$ArtifactPath\MOF"
    $ConfigPath = "$PSScriptRoot\Configs"
    $RequiredModules = @(@{Name='xDnsServer';Version='1.7.0.0'}, @{Name='xNetworking';Version='2.9.0.0'}) 
}

Task Default -depends UnitTests

Task GenerateEnvironmentFiles -Depends Clean {
     Exec {& $PSScriptRoot\DevEnv.ps1 -OutputPath $ConfigPath}
}

Task InstallModules -Depends GenerateEnvironmentFiles {
    # Install resources on build agent
    "Installing required resources..."

    #Workaround for bug in Install-Module cmdlet
    if(!(Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction Ignore))
    {
        Install-PackageProvider -Name NuGet -Force
    }
    
    if (!(Get-PSRepository -Name PSGallery -ErrorAction Ignore))
    {
        Register-PSRepository -Name PSGallery -SourceLocation https://www.powershellgallery.com/api/v2/ -InstallationPolicy Trusted -PackageManagementProvider NuGet
    }
    
    #End Workaround
    
    foreach ($Resource in $RequiredModules)
    {
        Install-Module -Name $Resource.Name -RequiredVersion $Resource.Version -Repository 'PSGallery' -Force
        Save-Module -Name $Resource.Name -RequiredVersion $Resource.Version -Repository 'PSGallery' -Path $ModuleArtifactPath -Force
    }
}

Task ScriptAnalysis -Depends InstallModules {
    # Run Script Analyzer
    "Starting static analysis..."
    Invoke-ScriptAnalyzer -Path $ConfigPath

}

Task UnitTests -Depends ScriptAnalysis {
    # Run Unit Tests with Code Coverage
    "Starting unit tests..."

    $PesterResults = Invoke-Pester -path "$TestsPath\Unit\"  -CodeCoverage "$ConfigPath\*.ps1" -OutputFile "$TestResultsPath\UnitTest.xml" -OutputFormat NUnitXml -PassThru
    
    if($PesterResults.FailedCount) #If Pester fails any tests fail this task
    {
        Invoke-TestFailure -TestType Unit -PesterResults $PesterResults
    }
    
}

Task CompileConfigs -Depends UnitTests, ScriptAnalysis {
    # Compile Configurations...
    "Starting to compile configuration..."
    . "$ConfigPath\DNSServer.ps1"

    DNSServer -ConfigurationData "$ConfigPath\DevEnv.psd1" -OutputPath "$MOFArtifactPath\DevEnv\"
    # Build steps for other environments can follow here.
}

Task Clean {
    "Starting Cleaning enviroment..."
    #Make sure output path exist for MOF and Module artifiacts
    New-Item $ModuleArtifactPath -ItemType Directory -Force 
    New-Item $MOFArtifactPath -ItemType Directory -Force 

    # No need to delete Artifacts as VS does it automatically for each build

    #Remove Test Results from previous runs
    New-Item $TestResultsPath -ItemType Directory -Force
    Remove-Item "$TestResultsPath\*.xml" -Verbose 

    #Remove ConfigData generated from previous runs
    Remove-Item "$ConfigPath\*.psd1" -Verbose

    #Remove modules that were installed on build Agent
    foreach ($Resource in $RequiredModules)
    {
        $Module = Get-Module -Name $Resource.Name
        if($Module  -And $Module.Version.ToString() -eq  $Resource.Version)
        {
            Uninstall-Module -Name $Resource.Name -RequiredVersion $Resource.Version
        }
    }

    $Error.Clear()
}
