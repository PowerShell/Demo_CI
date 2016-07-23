
Import-Module psake

Task Default -depends AcceptanceTests

Task GenerateEnvironmentFiles{
     Exec {& $PSScriptRoot\TestEnv.ps1}
}

Task ScriptAnalysis -Depends GenerateEnvironmentFiles {
    Import-Module PSScriptAnalyzer
     # Run Script Analyzer
    "Starting static analysis..."
    Invoke-ScriptAnalyzer -Path $PSScriptRoot\Configs 
}

Task UnitTests -Depends ScriptAnalysis {
    
    # Run Unit Tests
    "Starting unit tests..."
    Import-Module Pester
    Push-Location $PSScriptRoot\Tests\Unit\ 
    Invoke-Pester
    "Successfully completed unit tests." 
    
    # Run Code Coverage to ensure it is greater than 75%
    "Starting code coverage..."
    $Coverage = Invoke-Pester -CodeCoverage
    #Fail if code coverage is less than 75% 
}

Task CompileConfigs -Depends UnitTests {
    # Compile Configurations
    "Starting to compile configuration..."
     
}

Task IntegrationTests -Depends DeployConfigs, UnitTests {
    "Integration tests ran successfully"
}

Task DeployConfigs -Depends CompileConfigs {
    "Configs applied to target nodes"
    #push or Pull environment
}

Task AcceptanceTests -Depends DeployConfigs, IntegrationTests {
    "Acceptance tests processed"
}