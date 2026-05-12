<#
.SYNOPSIS
    SCCM detection script — does the installed VS instance match the target edition?

.DESCRIPTION
    Use as a detection method on the Install deployment type for Visual Studio.
    Edit $TargetCaption below to match the edition you're deploying.

    SCCM detection rules followed:
      - No 'exit' statements
      - Write-Output 'Installed' on success
      - Silent on miss

.NOTES
    Caption values (set $TargetCaption to match):
      'Visual Studio Professional 2022'
      'Visual Studio Enterprise 2022'
      'Visual Studio Community 2022'
      'Visual Studio Build Tools 2022'
#>

$TargetCaption = 'Visual Studio Professional 2022'   # <-- edit per deployment

$vs = Get-CimInstance MSFT_VSInstance -Namespace root/cimv2/vs -ErrorAction SilentlyContinue
if ($vs -and ($vs | Where-Object { $_.Caption -eq $TargetCaption })) {
    Write-Output 'Installed'
}
