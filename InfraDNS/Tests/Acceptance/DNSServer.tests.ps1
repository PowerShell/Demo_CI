####################################################################
# Acceptance tests for DNS server Configuration
#
# Acceptance tests:  DNS server is configured as intended.
####################################################################

Import-Module PoshSpec

Describe 'DNS' {
    DnsHost TestAgent1 {Should not be $null}
    DnsHost TestAgent2 {Should not be $null}
    DnsHost DNS.Contoso.com {Should not be $null}
}

Describe 'Http' {
    TcpPort TestAgent2 80 PingSucceeded { Should Be $true }
    TcpPort TestAgent2 80 TcpTestSucceeded { Should Be $true }
    Http http://TestAgent2 StatusCode { Should Be 200 }
    Http http://TestAgent2 Headers { Should Match 'Microsoft-IIS/10.0' }
    Http http://TestAgent2 RawContentLength { Should be 36919 }
    Http http://TestAgent2 Content { Should Match 'Pixel perfect design, created with love' }
}