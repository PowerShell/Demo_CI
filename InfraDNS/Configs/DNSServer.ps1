Configuration DNSServer
{
    Import-DscResource -Module PsDesiredStateConfiguration

    node $AllNodes.where{$_.Role -eq "DNSServer"}.NodeName
    {
        Environment Type
        {
            ensure   = 'Present'
            Name     = 'TypeOfServer'
            Value    = 'DNS'
        }
    }
}

<#
$zone = 'foo.io'

$ARecords = @{
    'bar1'='10.0.0.10';
    'bar2'='10.0.0.20';
    'bar3'='10.0.0.30';
    'bar4'='10.0.0.40';
    'bar5'='10.0.0.50';
    }

configuration DNS
{
    Import-DscResource -module 'xDnsServer','xNetworking','xPSDesiredStateConfiguration'
    
    xWindowsOptionalFeature DNS
    {
        Name = 'DNS-Server-Full-Role'
        Ensure = 'Present'
    }

     xDnsServerPrimaryZone $zone
    {
        Ensure = 'Present'                
        Name = $zone
        DependsOn = '[xWindowsOptionalFeature]DNS'
    }
        
    foreach ($a in $ARecords.keys) {
        xDnsRecord $a
        {
            Name = $a
            Zone = $zone
            Type = 'ARecord'
            Target = $ARecords[$a]
            Ensure = 'Present'
            DependsOn = '[xWindowsOptionalFeature]DNS'
        }
    }

    xFirewall TCP53
    {
        Name = 'DNS In TCP'
        Group = 'DNS Server'
        Ensure = 'Present'
        Protocol = 'TCP'
        LocalPort = 53
        RemotePort = 53
    }

    xFirewall UDP53
    {
        Name = 'DNS In UDP'
        Group = 'DNS Server'
        Ensure = 'Present'
        Protocol = 'UDP'
        LocalPort = 53
        RemotePort = 53
    }
}

#>