<#
.SYNOPSIS
    Add or remove a Visual Studio workload component (add-in) against an
    existing VS install, sourced from an offline layout.

.DESCRIPTION
    Drives `setup.exe modify --add` (or --Remove) for a specific workload or
    component ID, pointing the installer at the offline layout so the component
    bytes come from the share rather than the Microsoft CDN.

    Single script handles both Install and Uninstall via -Action.

.PARAMETER Action
    Install removes "--Remove", uses "--add". Uninstall uses "--Remove".

.PARAMETER ComponentId
    The workload or component ID. Find these in Microsoft's docs:
      https://learn.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
    Example: Microsoft.VisualStudio.Component.AspNet

.PARAMETER LayoutPath
    UNC path to the layout root for the installed edition. Used to set
    --installChannelUri and --channelUri so the modify operation pulls
    component packages from the layout, not the internet.

.PARAMETER LogDirectory
    Where Start-Transcript writes the run log.

.EXAMPLE
    .\Install-VSAddOn.ps1 -Action Install `
        -ComponentId Microsoft.VisualStudio.Component.AspNet `
        -LayoutPath '\\fileshare\Sources\VisualStudio\2022\Pro\VSLayout'

.EXAMPLE
    .\Install-VSAddOn.ps1 -Action Uninstall `
        -ComponentId Microsoft.VisualStudio.Component.AspNet `
        -LayoutPath '\\fileshare\Sources\VisualStudio\2022\Pro\VSLayout'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Install','Uninstall')]
    [string]$Action,

    [Parameter(Mandatory)]
    [string]$ComponentId,

    [Parameter(Mandatory)]
    [string]$LayoutPath,

    [string]$LogDirectory = (Join-Path $env:SystemDrive 'Distrib\logs')
)

$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
$safeId  = $ComponentId -replace '[^A-Za-z0-9.]', '_'
$logFile = Join-Path $LogDirectory ("AddOn-{0}-{1}.log" -f $Action, $safeId)
Start-Transcript -Path $logFile -Append

Write-Host "Action=$Action ComponentId=$ComponentId"
Write-Host "LayoutPath=$LayoutPath"

try {
    # Locate the installed VS instance — required to know what to modify.
    $vs = Get-CimInstance MSFT_VSInstance -Namespace root/cimv2/vs -ErrorAction Stop
    if (-not $vs) { throw "No installed Visual Studio instance found." }
    Write-Host ("Installed: {0} at {1}" -f $vs.Caption, $vs.InstallLocation)

    # Build the channel paths from the layout root.
    $manifest = Join-Path $LayoutPath 'ChannelManifest.json'
    if (-not (Test-Path -LiteralPath $manifest)) {
        throw "ChannelManifest.json not found in layout: $manifest"
    }

    # setup.exe verb depends on Action.
    $verb = if ($Action -eq 'Install') { '--add' } else { '--Remove' }

    $setupExe = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe'
    if (-not (Test-Path -LiteralPath $setupExe)) {
        throw "VS Installer setup.exe not found at $setupExe"
    }

    $argList = @(
        'modify',
        '--noUpdateInstaller', '--norestart', '--passive', '--noweb',
        $verb, $ComponentId,
        '--installPath',       "`"$($vs.InstallLocation)`"",
        '--installChannelUri', "`"$manifest`"",
        '--channelUri',        "`"$LayoutPath`""
    )

    $proc = Start-Process -FilePath $setupExe -ArgumentList $argList -Wait -PassThru
    Write-Host ("Exit code: {0}" -f $proc.ExitCode)
    Stop-Transcript
    exit $proc.ExitCode
}
catch {
    Write-Error $_
    Stop-Transcript
    exit 1
}
