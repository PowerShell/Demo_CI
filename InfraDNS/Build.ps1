
Import-Module psake
Import-Module $PSScriptRoot\..\Assets\DscPipelineTools\DscPipelineTools.psd1 -Force
 

FormatTaskName '--------------- {0} ---------------'

Properties {
    $TestsPath = Join-Path $PSScriptRoot 'Tests'
    $TestResultsPath = Join-Path $TestsPath 'Results'
    $ArtifactPath = "$Env:BUILD_ARTIFACTSTAGINGDIRECTORY"
    $ModuleArtifactPath = Join-Path $ArtifactPath 'Modules'
    $MOFArtifactPath = Join-Path $ArtifactPath 'MOF'
    $ConfigPath = Join-Path $PSScriptRoot 'Configs'
    $RequiredModules = @(@{Name='xDnsServer';Version='1.7.0.0'}, @{Name='xNetworking';Version='2.9.0.0'}) 
}

Task Default -depends UnitTests

Task GenerateEnvironmentFiles -Depends Clean {
     Exec {& (Join-Path $PSScriptRoot 'DevEnv.ps1') -OutputPath $ConfigPath}
}

Task InstallModules -Depends GenerateEnvironmentFiles {
    # Install resources on build agent
    'Installing required resources...'

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
        # This installs the required modules on the build agent so that the configuration can be compiled
        Install-Module -Name $Resource.Name -RequiredVersion $Resource.Version -Repository 'PSGallery' -Force
        # This copies the required modules to a directory so that they will be packaged up as artifacts for release
        Save-Module -Name $Resource.Name -RequiredVersion $Resource.Version -Repository 'PSGallery' -Path $ModuleArtifactPath -Force
    }
}

Task ScriptAnalysis -Depends InstallModules {
    # Run Script Analyzer
    'Starting static analysis...'
    Invoke-ScriptAnalyzer -Path $ConfigPath
}

Task UnitTests -Depends InstallModules {
    # Run Unit Tests with Code Coverage
    'Starting unit tests...'

    $PesterResults = Invoke-Pester -path "$(Join-Path $TestsPath 'Unit')"  `
                                   -CodeCoverage "$(Join-Path $ConfigPath '*.ps1')" `
                                   -OutputFile "$(Join-Path $TestResultsPath 'UnitTest.xml')" `
                                   -OutputFormat NUnitXml `
                                   -PassThru
    
    New-TestValidation -TestType Unit -PesterResults $PesterResults
}

Task CompileConfigs -Depends UnitTests, ScriptAnalysis {
    # Compile Configurations...
    'Starting to compile configuration...'
    Import-Module "$(Join-Path $ConfigPath 'DNSServer.ps1')"

    DNSServer -ConfigurationData "$(Join-Path $ConfigPath 'DevEnv.psd1')" `
              -OutputPath "$(Join-Path $MOFArtifactPath 'DevEnv')"

    
    # Build steps for other environments can follow here.
}

Task Clean {
    'Starting Cleaning enviroment...'
    #Make sure output path exist for MOF and Module artifiacts
    New-Item $ModuleArtifactPath -ItemType Directory -Force 
    New-Item $MOFArtifactPath -ItemType Directory -Force 

    # No need to delete Artifacts as VS does it automatically for each build

    #Remove Test Results from previous runs
    New-Item $TestResultsPath -ItemType Directory -Force
    Remove-Item "$(Join-Path $TestResultsPath '*.xml')" -Verbose 

    #Remove ConfigData generated from previous runs
    Remove-Item "$(Join-Path $ConfigPath '*.psd1')" -Verbose

    #Remove modules that were installed on build Agent
    foreach ($Resource in $RequiredModules)
    {
        $Module = Get-Module -Name $Resource.Name
        if($Module  -And $Module.Version.ToString() -eq  $Resource.Version)
        {
            Uninstall-Module -Name $Resource.Name -RequiredVersion $Resource.Version
        }
    }
}
