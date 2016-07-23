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

    if ($FileName.length -eq 0)
    {
        $FileName = $RawEnvData.Name
    }
    $OutFile = join-path $outputpath "$FileName.psd1"
    
    ## Loop through $RawEnvData and generate Configuration Document
    # Create AllNodes array based on input
    foreach ($Role in $RawEnvData.Roles)
    {
        $NumberOfServers = 0
        if($Role.VMQuantity -gt 0)
        {
            $NumberOfServers = $Role.VMQuantity
        }
        else
        {
            $NumberOfServers = $Role.VMName.Count
        }

        for($i = 1; $i -le $NumberOfServers; $i++)
        {
            $j = if($Role.VMQuantity -gt 0){$i}
            [hashtable]$NodeData =  @{    NodeName                = "$($Role.VMName)$j"
                                Role                    = $Role.Role
                            }
            # Remove Role and VMName from HT
            $role.remove("Role")
            $role.remove("VMName")

            # Add Lability properties to ConfigurationData if they are included in the raw hashtable
            if($Role.ContainsKey('VMProcessorCount')){ $NodeData  +=  @{Lability_ProcessorCount = $Role.VMProcessorCount}}
            if($Role.ContainsKey('VMStartupMemory')){$NodeData  +=  @{Lability_StartupMemory  = $Role.VMStartupMemory}}
            if($Role.ContainsKey('NetworkName')){    $NodeData  +=  @{Lability_SwitchName     = $Role.NetworkName}}
            if($Role.ContainsKey('VMMedia')){        $NodeData  +=  @{Lability_Media          = $Role.VMMedia}}
            
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
            
            [System.Array]$AllNodesData += $NodeData
        }
    }
    
    # Create NonNodeData hashtable based on input            
    foreach ($Network in $OtherEnvData )
    {
        [hashtable]$NetworkHash += @{
                            Name   = $Network.NetworkName;
                            Type   = $Network.SwitchType;
        }
        
        if ($Network.ContainsKey('ExternalAdapterName'))
        {
            $NetworkHash += @{
                            NetAdapterName      = $Network.ExternalAdapterName;
                            AllowManagementOS   = $true;
            }
        }
        
        $NetworkData += $NetworkHash
    }
    
    $NonNodeData = if($NetworkData){ @{Lability=@{Network = $NetworkData}}}
    $ConfigData = @{AllNodes = $AllNodesData; NonNodeData = $NonNodeData}
    

    if(!(Test-path $OutputPath))
    {
        New-Item $OutputPath -ItemType Directory
    }
    
    import-module $PSScriptRoot\Visualization.psm1
    $ConfigData | convertto-ScriptBlock | Out-File $OutFile
    $FullFileName = dir $OutFile
    
    Return "Successfully created file $FullFileName"
}

# Get list of resources required by a configuration script
function Get-DscRequiredResources ()
{
    param(
        [Parameter(Mandatory)]
        [string[]]
        $Path
    )
    
    
}