Configuration DNSServer
{
    import-dscresource -module PsDesiredStateConfiguration

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

DNSServer -OutputPath c:\Configs\