####################################################################
# Integration tests for DNSServer Config
#
# Integration tests:  DNS server is configured as intended.
####################################################################

Describe 'Services' {    
    Service w32time Status { Should Be Running }
    Service bits Status { Should Be Stopped }
}
