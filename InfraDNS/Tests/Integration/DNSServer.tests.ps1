####################################################################
# Integration tests for DNSServer Config
#
# Integration tests:  DNS server is configured as intended.
####################################################################

Import-Module PoshSpec

Describe 'DNS Server' {    
    context "Installed and running" {
        Service DNS Status { Should Be Running }
        It "Should have feature installed" {
            (Get-WindowsFeature -Name DNS).InstallState | Should be 'Installed'
        }
    }
    
    context 'Inbound DNS rules' {
        $InboundRules = (Get-NetFirewallRule -DisplayGroup "DNS Service" | where {$_.Direction -eq 'Inbound'})
        
        It "Should have 4 rules" {
            $InboundRules.count | Should be 4
        }

        It "All rules should be enabled" {
            $InboundRules | %{if(!($_.enabled -eq $true)){"Failed!"}} | Should be $null
        }

        It "All rules should not block traffic" {
            $InboundRules | %{if(!($_.Action -eq "Allow")){"Failed!"}} | Should be $null
        }

        It "Should be a rule for local TCP port 53" {
            ($InboundRules | Get-NetFirewallPortFilter | ?{$_.Protocol -eq "TCP" -and $_.LocalPort -eq 53}).LocalPort | Should match 53
        }

        It "Should be a rule for local UDP port 53" {
            ($InboundRules | Get-NetFirewallPortFilter | ?{$_.Protocol -eq "UDP" -and $_.LocalPort -eq 53}).LocalPort | Should match 53
        }
    }

    context 'Outbound DNS rules' {
        $OutboundRules = (Get-NetFirewallRule -DisplayGroup "DNS Service" | where {$_.Direction -eq 'Outbound'})

       It "Should have 2 rules" {
            $OutboundRules.count | should be 2
        }

        It "All rules should be enabled" {
            $OutboundRules | %{if(!($_.enabled -eq $true)){"Failed!"}} | Should be $null
        }

        It "All rules should not block traffic" {
            $OutboundRules | %{if(!($_.Action -eq "Allow")){"Failed!"}} | Should be $null
        }

        It "Should be a rule for TCP on any port" {
            ($OutboundRules | Get-NetFirewallPortFilter | ?{$_.Protocol -eq "TCP"}).LocalPort | Should be 'Any'
        }

        It "Should be a rule for UDP on any port" {
            ($OutboundRules | Get-NetFirewallPortFilter | ?{$_.Protocol -eq "UDP"}).LocalPort | Should be 'Any'
        }

    }

    context 'DNS records' {
        It "Should have an A record for TestAgent1 (DNS Server)" {
            (Get-DnsServerResourceRecord -Name TestAgent1 -ZoneName contoso.com).RecordData.Ipv4Address.IpAddressToString | Should be '10.0.0.40'
        }

        It "Should have an A record for TestAgent2 (Web Server)" {
            (Get-DnsServerResourceRecord -Name TestAgent2 -ZoneName contoso.com).RecordData.Ipv4Address.IpAddressToString | Should be '10.0.0.50'
        }

        It "Should have a CName record for DNS pointing to TestAgent1" {
            (Get-DnsServerResourceRecord -Name dns -ZoneName contoso.com -ErrorAction SilentlyContinue).RecordData.HostNameAlias | Should match 'TestAgent1.'
        }
    }
}
