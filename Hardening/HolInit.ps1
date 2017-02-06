# Set up trusted hosts
Write-Verbose "Initializing WinRM ..."
Start-Service winrm
Set-Item WSMan:\localhost\Client\TrustedHosts -Value * -Force

# Set Credential
Write-Verbose "Creating VM Credential ..."
$UserName = 'DscDemo'
$Password = ConvertTo-SecureString -String "Power0fTh3She11" -AsPlainText -Force
$Cred =  New-Object System.Management.Automation.PsCredential -ArgumentList $UserName, $Password

# Pick 3 of a set of pre-define Servers
Write-Verbose "Selecting 3 servers from Azure pool ..."
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
Write-Verbose "Creating CIM sessions ..."
$Sessions = New-CimSession -Authentication Negotiate -ComputerName $Servers -Credential $Cred -ErrorAction SilentlyContinue

# Fall back to connecting to Server1 if cannot connect to Azure VMs for any reason
if ($Sessions.Count -eq 0){
    $Sessions = New-CimSession Server1
}
