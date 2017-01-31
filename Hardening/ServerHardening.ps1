Configuration ServerHardening
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node "Server1"
    {
        User Guest
        {
            Ensure = 'Present'
            UserName = 'Guest'
            Disabled = $true
        }

        User Default
        {
            Ensure = 'Present'
            UserName = 'DefaultAccount'
            Disabled = $true
        }

        WindowsFeatureSet DisallowedFeatures
        {
            Ensure = 'Absent'
            Name = @(   'Remote-Desktop-Services',
                        'Web-Ftp-Server', 
                        'Web-Basic-Auth', 
                        'Web-Dir-Browsing', 
                        'SNMP-Service',
                        'ServerEssentialsRole')
        }

        WindowsFeatureSet RequiredFeatures
        {
            Ensure = 'Present'
            Name = @(   'Web-Health', 
                        'BitLocker',
                        'NET-Framework-45-Features',
                        'Windows-Defender-Features',
                        'Windows-Server-Backup')
        }

        ServiceSet DisallowedServices
        {
            Name = @(   'defragsvc',
                        'seclogon',
                        'SharedAccess',
                        'Themes')
            State = 'Stopped'
            StartupType = 'Disabled' 
        }

        Environment Corp
        {
            Name = 'PropertyOf'
            Value = 'Contoso'
        }

        Environment Team
        {
            Name = 'ManagedBy'
            Value = 'CentralIT'
        }

        GroupSet DomainUser
        {
            Ensure = 'Present'
            GroupName = @('Administrators','Backup Operators','Remote Management Users', 'Power Users')
            MembersToExclude = 'contoso\bensmith'
        }
    }
}

ServerHardening -OutputPath c:\Configs\Mofs\Hardening
