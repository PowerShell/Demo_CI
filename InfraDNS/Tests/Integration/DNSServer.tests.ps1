####################################################################
# Integration tests for DNSServer Config
#
# Integration tests:  DNS server is configured as intended.
####################################################################

Import-Module PoshSpec

Describe 'Services' {    
    Service w32time Status { Should Be Stopped }
    Service bits Status { Should Be Stopped }
}