####################################################################
# Acceptance tests for DNS server Configuration
#
# Acceptance tests:  DNS server is configured as intended.
####################################################################

Import-Module PoshSpec

Describe 'Http' {
    #TcpPort TestAgent1 80 PingSucceeded { Should Be $true }
    #TcpPort TestAgent1 80 TcpTestSucceeded { Should Be $true }
    Http http://TestAgent1 StatusCode { Should Be 200 }
    #Http http://TestAgent1 RawContent { Should Match 'X-Powered-By: ASP.NET' }
    #Http http://TestAgent1 RawContent { Should Not Match 'X-Powered-By: Cobal' }
}