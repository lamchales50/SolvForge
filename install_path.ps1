$ErrorActionPreference = 'Stop'
$bin = (Resolve-Path $PSScriptRoot).Path
$old = [Environment]::GetEnvironmentVariable('Path', 'User')
$parts = @($old -split ';' | Where-Object { $_ -and $_.Trim() -ne $bin })
[Environment]::SetEnvironmentVariable('Path', (($parts + $bin) -join ';'), 'User')
Write-Host "SolvForge was added to the current user's PATH. Please reopen PowerShell."
