# Set up trusted hosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value *

# Set Credential
$Cred = Get-Credential Administrator

# Define Servers
$Servers = @(‘ dscholvm-1.westus2.cloudapp.azure.com’, ‘dscholvm-2.westus2.cloudapp.azure.com’, ‘dscholvm-3.westus2.cloudapp.azure.com’)

# Create sessions
$Sessions = New-CimSession -Authentication Negotiate -ComputerName $Servers -Credential $Cred