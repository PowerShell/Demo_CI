Invoke-PSake $PSScriptRoot\InfraDNS\build.ps1 -ErrorVariable PSakeResult

if($PSakeResult.count) #If any errors are returned then throw error so TFS shows Build scritp failure.
{
    Throw $PSakeResult[0]
}