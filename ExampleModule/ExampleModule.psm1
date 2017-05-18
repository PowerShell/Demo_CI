<#
.SYNOPSIS
    Example function that returns a string, 'Hello, World'
.EXAMPLE
    Get-Example1

    Returns 'Hello, World'
#>
Function Get-Example1 {

    [Alias('Example1')]
    [CmdletBinding()]
    param(
    )
    Write-Output 'Hello, World'
}

<#
.SYNOPSIS
    Example function that accepts input and returns it as output
.EXAMPLE
    Get-Example2 -text 'Hello, Word'

    Returns 'Hello, World'
#>
Function Get-Example2 {
    [Alias('Example2')]
    [CmdletBinding()]
    param(
        [string]$text
    )
    Write-Output $text
}

<#
.SYNOPSIS
    Example function that accepts two integers and adds them
.EXAMPLE
    Get-Example3 -First 3 -Second 5

    Returns 8
#>
Function Get-Example3 {
    [Alias('Example3')]
    [CmdletBinding()]
    param(
        [int32]$First,
        [int32]$Second
    )
    $Output = $First + $Second
    Write-Output $Output
}
