####################################################################
# Acceptance tests for DNS server Configuration
#
# Acceptance tests:  DNS server is configured as intended.
####################################################################

Import-Module PoshSpec

Describe 'Web Server E2E' {
    Context 'DNS addressess' {
        It "Should resolve TestAgent1 to 10.0.0.40" {
            (Resolve-DnsName -Name testagent1.contoso.com -DnsOnly -NoHostsFile).IPAddress | Should be '10.0.0.40' 
        }
        
        It "Should resolve TestAgent2 to 10.0.0.50" {
            (Resolve-DnsName -Name testagent2.contoso.com -DnsOnly -NoHostsFile).IPAddress | Should be '10.0.0.50' 
        }

        It "Should resolve DNS to TestAgent1" {
            (Resolve-DnsName -Name dns.contoso.com -DnsOnly -NoHostsFile).NameHost | Should be 'TestAgent1' 
        }
    }
    
    Context 'Web server ports' {

        $PortTest = Test-NetConnection -ComputerName testagent2.contoso.com -Port 80

        It "Should successfully Test TCP port 80" {
            $PortTest.TcpTestSucceeded | Should be $true 
        }

        It "Should successfully ping port 80" {
            $PortTest.PingSucceeded | Should be $false
        }
    }

    Context 'Website content' {
        $WebRequest = Invoke-WebRequest -Uri http://testagent2.contoso.com -UseBasicParsing

        It "Should have a status code of 200" {
            $WebRequest.StatusCode | Should be 200
        }
        
        It "Should have appropriate headers" {
            $WebRequest.Headers.Server | Should Match 'Microsoft-IIS/10.0'
        }

        It "Should have expected raw content length" {
            $WebRequest.RawContentLength | Should be 36919
        }

        It "Should have expected raw content" {
            $WebRequest.Content | Should Match 'Pixel perfect design, created with love'
        }
    }
    
}