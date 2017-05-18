<#
.SYNOPSIS
    Example function that returns a string, 'Hello, World'
.EXAMPLE
    New-Example1

    Returns 'Hello, World'
#>
Function New-Example1 {

    [Alias('Example1')]
    [CmdletBinding()]
    param()
    Write-Output 'Hello, World'
}

<#
.SYNOPSIS
    Example function that accepts input and returns it as output
.EXAMPLE
    New-Example2 -text 'Hello, Word'

    Returns 'Hello, World'
#>
Function New-Example2 {
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
    New-Example3 -First 3 -Second 5

    Returns 8
#>
Function New-Example3 {
    [Alias('Example3')]
    [CmdletBinding()]
    param(
        [int32]$First,
        [int32]$Second
    )
    $Output = $First + $Second
    Write-Output $Output
}
