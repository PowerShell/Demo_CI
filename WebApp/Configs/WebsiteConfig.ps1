Configuration Website
{
    import-dscresource -module PsDesiredStateConfiguration

    node $AllNodes.where{$_.Role -eq "Website"}.NodeName
    {
        Environment Type
        {
            ensure   = 'Present'
            Name     = 'TypeOfServer'
            Value    = 'Web'
        }
    }
}

Website -OutputPath c:\Configs\

<# Removing config temporarily
Configuration Website
{
    param
    (
        # Source Path for Website content
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SourcePath,

        # Name of the website to create
        [Parameter()]
        [String]$WebSiteName = 'FourthCoffee',

        # Destination path for Website content
        [Parameter()]
        [String]$DestinationRootPath = 'c:\inetpub\'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node "Website.$WebSiteName"
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

        # Install the ASP .NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
        }

        # Stop the default website
        xWebsite DefaultSite 
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }

        # Copy the website content
        Archive WebContent
        {
            Ensure          = "Present"
            Path            = "$SourcePath\BakeryWebsite.zip"
            Destination     =  $DestinationPath
            DependsOn       = "[WindowsFeature]AspNet45"
        }       

        # Create the new Website
        xWebsite BakeryWebSite 
        {
            Ensure          = "Present"
            Name            = $WebSiteName
            State           = "Started"
            PhysicalPath    = "$DestinationPath\BakeryWebsite"
            DependsOn       = "[Archive]WebContent"
        }
    }
}
#>