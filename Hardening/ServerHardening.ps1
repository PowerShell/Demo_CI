Configuration ServerHardening
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node "Server1"
    {
        # Make sure that the Guest and DefaultAccount are disabled.
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

        #User Account Control - prompt admin 
        Registry ConsentPromptBehaviorAdmin
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "ConsentPromptBehaviorAdmin"
            ValueType = "Dword"
            ValueData = "5"
        }  

        #Interactive logon: Number of previous logons to cache (in case domain controller is not available)
        Registry Numberofpreviouslogonstocache
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
            ValueName = "CachedLogonsCount"
            ValueType = "Dword"
            ValueData = "2"
        }


        # Use the WindowsFeatureSet resource to ensure that a set Features are absent.
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

        # Use the WindowsFeatureSet resource to ensure that a set features are present.
        WindowsFeatureSet RequiredFeatures
        {
            Ensure = 'Present'
            Name = @(   'Web-Health', 
                        'BitLocker',
                        'NET-Framework-45-Features',
                        'Windows-Defender-Features',
                        'Windows-Server-Backup')
        }

        # Use the ServiceSet resource to stop and disable a set of services.
        ServiceSet DisallowedServices
        {
            Name = @(   'defragsvc',
                        'seclogon',
                        'SharedAccess',
                        'Themes')
            State = 'Stopped'
            StartupType = 'Disabled' 
        }

        # Add a few environment variables that can be used by applications or other configurations.
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

        # Use the GroupSet resource to make sure a specific user is not in any of the specified groups.
        GroupSet DomainUser
        {
            Ensure = 'Absent'
            GroupName = @('Administrators','Backup Operators','Remote Management Users', 'Power Users')
            MembersToExclude = 'contoso\bensmith'
        }
    }
}

ServerHardening -OutputPath c:\Configs\Mofs\Hardening