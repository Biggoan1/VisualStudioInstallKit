<#
.SYNOPSIS
    SCCM detection script — is a specific Visual Studio workload component installed?

.DESCRIPTION
    Generic detection for any VS workload or component. Edit $ComponentId
    below for the specific add-in you're deploying, then attach this script
    to that add-in's deployment type.

    Uses vswhere.exe (Microsoft's official tool, shipped with the VS Installer)
    to query installed components. vswhere -requires <ComponentId> returns
    instances that have the component; if the JSON is non-empty, present.

    SCCM detection rules followed:
      - No 'exit' statements
      - Write-Output 'Installed' on success
      - Silent on miss

.NOTES
    Component IDs: https://learn.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
    Example IDs:
      Microsoft.VisualStudio.Component.AspNet
      Microsoft.VisualStudio.Workload.Azure
      Microsoft.VisualStudio.Component.Roslyn.Compiler
#>

$ComponentId = 'Microsoft.VisualStudio.Component.AspNet'   # <-- edit per deployment

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path -LiteralPath $vswhere)) { return }

$json = & $vswhere -products '*' -requires $ComponentId -format json -nologo 2>$null
if (-not $json) { return }

try {
    $instances = $json | ConvertFrom-Json
    if ($instances -and $instances.Count -gt 0) {
        Write-Output 'Installed'
    }
} catch {
    # JSON parse failed; treat as not detected.
}
