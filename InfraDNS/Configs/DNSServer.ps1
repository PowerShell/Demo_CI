
configuration DNSServer
{
    Import-DscResource -module 'xDnsServer','xNetworking'
    
    Node $AllNodes.Where{$_.Role -eq 'DNSServer'}.NodeName
    {
        WindowsFeature DNS
        {
            Ensure  = 'Present'
            Name    = 'DNS'
        }

        xDnsServerPrimaryZone $zone
        {
            Ensure    = 'Present'                
            Name      = $Node.Zone
            DependsOn = '[WindowsFeature]DNS'
        }
            
        foreach ($ARec in $Node.ARecords.keys) {
            xDnsRecord $ARec
            {
                Ensure    = 'Present'
                Name      = $ARec
                Zone      = $Node.Zone
                Type      = 'ARecord'
                Target    = $ARecords[$ARec]
                DependsOn = '[WindowsFeature]DNS'
            }
        }

        xFirewall TCP53
        {
            Ensure     = 'Present'
            Name       = 'DNS In TCP'
            Group      = 'DNS Server'
            Protocol   = 'TCP'
            LocalPort  = 53
            RemotePort = 53
        }

        xFirewall UDP53
        {
            Ensure     = 'Present'
            Name       = 'DNS In UDP'
            Group      = 'DNS Server'
            Protocol   = 'UDP'
            LocalPort  = 53
            RemotePort = 53
        }
    }
}