# Set up trusted hosts
Start-Service winrm
Set-Item WSMan:\localhost\Client\TrustedHosts -Value * -Force

# Set Credential
$UserName = 'DscDemo'
$Password = ConvertTo-SecureString -String "P0werOfTh3She11" -AsPlainText -Force
$Cred =  New-Object System.Management.Automation.PsCredential -ArgumentList $UserName, $Password

# Pick 3 of a set of pre-define Servers
$Servers = @()
for($count=0; $count -lt 3; $count++){
    $i = Get-Random -min 1 -max 30
    $unique = $true
    do {
        if($Servers -notcontains "dscholvm$i.westus2.cloudapp.azure.com"){
            $Servers += "dscholvm$i.westus2.cloudapp.azure.com"
            $unique = $false
        }
    } while ($unique)
}

# Create sessions
$Sessions = New-CimSession -Authentication Negotiate -ComputerName $Servers -Credential $Cred
