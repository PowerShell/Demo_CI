# Generate PowerShell Document file(s)
function New-DscConfigurationDataDocument
{
    param(
        [parameter(Mandatory)]
        [hashtable]
        $RawEnvData, 
        
        [array]
        $OtherEnvData,
        
        [string]
        $OutputPath = '.\', 
        
        [ValidateNotNullorEmpty()]
        [string]
        $FileName
        
    )
    
    [System.Array]$AllNodesData
    [System.Array]$NetworkData

    #First validate that the path passed in is not a file
    if(!(Test-Path $outPutPath -IsValid) -or (Test-Path $outPutPath -PathType Leaf))
    {
        Throw "The OutPutPath parameter must be a valid path and must not be an existing file." 
    }

    if (-not $PSboundParameters['FileName'])
    {
        $FileName = $RawEnvData.Name
    }
    $OutFile = join-path $outputpath "$FileName.psd1"
    
    ## Loop through $RawEnvData and generate Configuration Document
    # Create AllNodes array based on input
    $AllNodesData = foreach ($Role in $RawEnvData.Roles)
    {
        $NumberOfServers = 0
        $VMName = [array]$Role.VMName

        if($Role.VMQuantity -gt 0)
        {
            $NumberOfServers = $Role.VMQuantity
        }
        else
        {
            $NumberOfServers = $Role.VMName.Count
        }

        for($i = 0; $i -lt $NumberOfServers; $i++)
        {
            $NodeData =  @{    NodeName  = if($Role.VMQuantity -gt 0) {
                                                "$($VMName[0])$i"
                                            } else {
                                                write-verbose "VMName = $VMName   i = $i"
                                                "$($VMName[$i])"
                                            }
                                Role     = $Role.Role
                            }
            # Remove Role and VMName from HT
            $role.remove("Role")
            $role.remove("VMName")
            $role.remove("VMQuantity")

            # Add Lability properties to ConfigurationData if they are included in the raw hashtable
            if($Role.ContainsKey('VMProcessorCount')){ $NodeData['Lability_ProcessorCount'] =  $Role.VMProcessorCount}
            if($Role.ContainsKey('VMStartupMemory')){$NodeData['Lability_StartupMemory']  = $Role.VMStartupMemory}
            if($Role.ContainsKey('NetworkName')){    $NodeData['Lability_SwitchName']     = $Role.NetworkName}
            if($Role.ContainsKey('VMMedia')){        $NodeData['Lability_Media']          = $Role.VMMedia}
            
            # Add all other properties
            $Role.keys | % {$NodeData += @{$_ = $Role.$_}}

            # Generate networking data for static networks 
            Foreach ($Network in $OtherEnvData)
            {
                if($Network.NetworkName -eq $Role.NetworkName -and $network.IPv4AddressAssignment -eq 'Static')
                {
                    # logic to add networking information
                }
            }
            
            $NodeData
        }
    }
    
    # Create NonNodeData hashtable based on input            
    $NetworkData = foreach ($Network in $OtherEnvData )
    {
        @{
            Name   = $Network.NetworkName;
            Type   = $Network.SwitchType;
        }
        
        if ($Network.ContainsKey('ExternalAdapterName'))
        {
            @{
                NetAdapterName      = $Network.ExternalAdapterName;
                AllowManagementOS   = $true;
            }
        }
    }
    
    $NonNodeData = if($NetworkData){ @{Lability=@{Network = $NetworkData}}}
    $ConfigData = @{AllNodes = $AllNodesData; NonNodeData = $NonNodeData}
    

    if(!(Test-path $OutputPath))
    {
        New-Item $OutputPath -ItemType Directory
    }
    
    Import-Module $PSScriptRoot\Visualization.psm1
    $ConfigData | ConvertTo-ScriptBlock | Out-File $OutFile
    $FullFileName = dir $OutFile
    
    "Successfully created file $FullFileName"
}

function New-TestValidation
{
    param(
        [parameter(Mandatory=$true)]
        [validateSet('Unit','Integration','Acceptance')]
        [string]$TestType,

        [parameter(Mandatory=$true)]
        $PesterResults
    )

    if($PesterResults.FailedCount) #If Pester fails any tests fail this task
    {
        $errorID = switch ($TestType) {
                                        'Unit' { 'UnitTestFailure' }
                                        'Integration' { 'InetegrationTestFailure' }
                                        'Acceptance' { 'AcceptanceTestFailure' }
                                        Default {}
                                    }
        $errorCategory = [System.Management.Automation.ErrorCategory]::LimitsExceeded
        $errorMessage = "$TestType Test Failed: $($PesterResults.FailedCount) tests failed out of $($PesterResults.TotalCount) total test."
        $exception = New-Object -TypeName System.SystemException -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception,$errorID, $errorCategory, $null

        Write-Output "##vso[task.logissue type=error]$errorMessage"
        Throw $errorRecord
    }
}