param(
    [parameter()]
    [ValidateSet('Build','Deploy')]
    [string]
    $fileName
)


Invoke-PSake $PSScriptRoot\InfraDNS\$fileName.ps1 -ErrorVariable PSakeErrors

if($PSakeErrors.count)
{
    Throw "$fileName script failed. Check logs for failure details."
}
