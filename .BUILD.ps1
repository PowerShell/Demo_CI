<#
.Synopsis
    Build script for example module

.Description
    The script automates tasks:
    * Update module manifest
    * Run PowerShell Script Analyzer
    * Copy the module to the Modules path in Program Files on the build node
    * Publish the module to a repository
#>

# Build script parameters are standard parameters
param(
    [Parameter(Mandatory=$true)]
    [string]$APIKEY,
    [Parameter(Mandatory=$true)]
    [string]$ModuleName,
    [int32]$Major       = 0,
    [int32]$Minor       = 1,
    [string]$Repository = 'PrivateFeed'
)

# Ensure Invoke-Build works in the most strict mode.
Set-StrictMode -Version Latest
task Clean {
    $CleanModule    = Remove-Item "$env:userprofile\Documents\WindowsPowerShell\Modules\$ModuleName" -Recurse -Force
}
# Synopsis: Run PowerShell Script Analyzer
task Clean {
    $CleanModule    = Remove-Item "$env:userprofile\Documents\WindowsPowerShell\Modules\$ModuleName" -Recurse -Force
}

# Synopsis: Run PowerShell Script Analyzer
task Update {
    Update-ModuleManifest -Path $env:BUILD_SOURCESDIRECTORY\$ModuleName\$ModuleName.psd1 -ModuleVersion "$Major.$Minor.$env:BUILD_BUILDNUMBER"
}

# Synopsis: Run PowerShell Script Analyzer
task ScriptAnalyzer {
    Invoke-ScriptAnalyzer -Path $env:BUILD_SOURCESDIRECTORY\$ModuleName -Settings PSGallery -Recurse
}

# Synopsis: Run Pester tests
task Pester {
    Invoke-Pester -OutputFormat NUnitXml -OutputFile $env:BUILD_SOURCESDIRECTORY\TestResults.Xml -EnableExit
}

# Synopsis: Copy the module to the Modules path in Program Files on the build node
task Copy {
    $ModuleFolder   = New-Item "$env:userprofile\Documents\WindowsPowerShell\Modules\$ModuleName" -ItemType Directory
    $CopyModule     = Copy-Item "$env:BUILD_SOURCESDIRECTORY\$ModuleName" $ModuleFolder -Recurse
}

# Synopsis: Publish the module to a repository
task Publish {
    Register-PSRepository -Name $Repository -SourceLocation $env:SourceLocation -PublishLocation $env:PublishLocation
    Publish-Module -Name 'ExampleModule' -NuGetApiKey $APIKEY -Repository $Repository
}

# Synopsis: The default task: make and test all, then clean.
task . Update, Copy, Publish, Clean
# task . Update, Pester, Copy, Publish, Clean
