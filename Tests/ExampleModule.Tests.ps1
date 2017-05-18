$ModuleManifestName = 'ExampleModule.psd1'
$ModuleManifestPath = "$env:BUILD_SOURCESDIRECTORY\ExampleModule\$ModuleManifestName"

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $ModuleManifestPath
        $? | Should Be $true
    }
}

Describe 'Testing against PSSA rules' {
    Context 'PSSA Standard Rules' {
        $analysis = Invoke-ScriptAnalyzer -Path $env:BUILD_SOURCESDIRECTORY\$ModuleName -Settings PSGallery -Recurse
        $scriptAnalyzerRules = Get-ScriptAnalyzerRule
        
        forEach ($rule in $scriptAnalyzerRules) {
            It "Should pass $rule" {
                If ($null -ne $analysis) {
                    If ($analysis.RuleName -contains $rule) {
                        $failures = $analysis | Where-Object {$_.RuleName -EQ $rule}
                        foreach ($failure in $failures) {Write-Warning $failure.Message}
                        $failures | Should BeNullOrEmpty
                    }
                }
            }
        }
    }
}
