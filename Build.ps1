
if (test-path c:\Temp)
{
    New-Item -Path c:\Temp\ -ItemType Directory
}

"This is only a build test" | Out-File -FilePath c:\Temp\test.txt -Encoding ascii -Append

start-sleep -seconds 30