Param(
    [string]$ExportPath = $null
)

$paths = @(
  'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

# Collect entries safely
$entries = foreach ($p in $paths) {
    Get-ItemProperty -Path $p -ErrorAction SilentlyContinue
}

# Filter to "Unknown" installs: have a name but no version
$unknowns = $entries | Where-Object {
    $_.DisplayName -and ([string]::IsNullOrWhiteSpace($_.DisplayVersion))
}

if (-not $unknowns) {
    Write-Host "No 'Unknown' installs found. You're all clean. 🎉"
    return
}

# Pretty console output
$unknowns |
    Sort-Object DisplayName |
    Format-Table -AutoSize DisplayName, Publisher, InstallLocation

# Export full details to CSV
if (-not $ExportPath) {
    $ExportPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath ("unknown_installs_{0}.csv" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
}

$unknowns |
    Select-Object DisplayName, Publisher, DisplayVersion, InstallLocation, UninstallString, PSPath |
    Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

Write-Host "`nSaved details to $ExportPath"
