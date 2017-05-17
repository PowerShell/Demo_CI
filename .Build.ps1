<#
.Synopsis
    Build script for example module

.Description
    The script automates tasks:
    * Run PowerShell Script Analyzer
    * Copy the module to the Modules path in Program Files on the build node
    * Publish the module to a repository
#>

# Build script parameters are standard parameters
param(
)

# Ensure Invoke-Build works in the most strict mode.
Set-StrictMode -Version Latest

# Synopsis: Run PowerShell Script Analyzer
task Clean {
    Remove-Item $env:ProgramFiles\ExampleModule\ -Recurse -Force
}

# Synopsis: Run PowerShell Script Analyzer
task ScriptAnalyzer {

}

# Synopsis: Copy the module to the Modules path in Program Files on the build node
task Copy {
    New-Item -Path $env:ProgramFiles\ExampleModule\ -ItemType 'directory'
    Copy-Item -Path $env:BUILD_SOURCESDIRECTORY\ExampleModule\ -Destination $env:ProgramFiles\ExampleModule\ -Recurse
}

# Synopsis: Publish the module to a repository
task Publish {
    Publish-Module -Name 'ExampleModule' -NuGetApiKey $env:APIKEY -Repository MyGet
}

# Synopsis: The default task: make and test all, then clean.
task . ScriptAnalyzer, Copy, Publish, Clean
