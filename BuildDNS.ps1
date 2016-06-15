$error.clear()
Invoke-PSake $PSScriptRoot\InfraDNS\build.ps1
if($error.count -gt 0)
{
    Throw $error[0]
}