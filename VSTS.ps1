Install-Module InvokeBuild,PSScriptAnalyzer -Force
Register-PSRepository -Name MyGet -SourceLocation $env:SourceLocation -PublishLocation $env:PublishLocation
Invoke-Build