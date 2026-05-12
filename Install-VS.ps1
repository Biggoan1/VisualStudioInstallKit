<#
.SYNOPSIS
    Install, update, or uninstall Visual Studio from an offline layout share.

.DESCRIPTION
    Unified deployment script for Visual Studio Professional or Enterprise. Drives
    install, update, and uninstall through the layout bootstrapper (install/update)
    or the installed VS Installer (uninstall). Designed to be called by an SCCM
    Script deployment type — one script, three deployment types per edition.

.PARAMETER Action
    Install   - Fresh install using --noWeb against the layout.
    Update    - Update the installed instance against the layout's current channel.
    Uninstall - Uninstall the currently installed VS instance (any edition).

.PARAMETER Edition
    Professional or Enterprise. Determines which bootstrapper inside the layout
    path is launched.

.PARAMETER LayoutPath
    UNC path to the layout root containing the edition's bootstrapper.
    Example: \\fileshare.example.local\Sources\VisualStudio\2022\Pro\VSLayout

.PARAMETER Workloads
    Optional. Array of workload IDs to add on install. Defaults to a typical
    .NET dev set; override for environments with different needs. See:
    https://learn.microsoft.com/en-us/visualstudio/install/workload-and-component-ids

.PARAMETER LogDirectory
    Where Start-Transcript writes the run log. Defaults to %SystemDrive%\Distrib\logs.

.EXAMPLE
    .\Install-VS.ps1 -Action Install -Edition Professional `
        -LayoutPath '\\fileshare\Sources\VisualStudio\2022\Pro\VSLayout'

.EXAMPLE
    .\Install-VS.ps1 -Action Update -Edition Professional `
        -LayoutPath '\\fileshare\Sources\VisualStudio\2022\Pro\VSLayout'

.EXAMPLE
    .\Install-VS.ps1 -Action Uninstall -Edition Professional `
        -LayoutPath '\\fileshare\Sources\VisualStudio\2022\Pro\VSLayout'

.NOTES
    Exit codes 0, 3010, and 1641 should all be treated as success in SCCM.
    See https://github.com/Biggoan1/VisualStudioInstallKit for details.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Install','Update','Uninstall')]
    [string]$Action,

    [Parameter(Mandatory)][ValidateSet('Professional','Enterprise')]
    [string]$Edition,

    [Parameter(Mandatory)]
    [string]$LayoutPath,

    [string[]]$Workloads = @(
        'Microsoft.VisualStudio.Workload.ManagedDesktop'
    ),

    [string]$LogDirectory = (Join-Path $env:SystemDrive 'Distrib\logs')
)

$ErrorActionPreference = 'Stop'

# --- Logging -----------------------------------------------------------------
New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
$logFile = Join-Path $LogDirectory ("{0}-{1}-{2}.log" -f $MyInvocation.MyCommand.Name, $Action, $Edition)
Start-Transcript -Path $logFile -Append

Write-Host "Action=$Action Edition=$Edition"
Write-Host "LayoutPath=$LayoutPath"

# --- Path-length sanity check -----------------------------------------------
# Microsoft documents a layout path limit of fewer than 80 characters:
# https://learn.microsoft.com/en-us/visualstudio/install/create-a-network-installation-of-visual-studio
if ($LayoutPath.Length -ge 80) {
    Write-Warning ("LayoutPath is {0} characters. Microsoft documents an 80-character limit on layout paths; installs may fail or produce confusing MAX_PATH errors. Consider a shorter path or a symbolic link." -f $LayoutPath.Length)
}

# --- Resolve the bootstrapper inside the layout ------------------------------
$bootstrapperName = switch ($Edition) {
    'Professional' { 'vs_professional.exe' }
    'Enterprise'   { 'vs_enterprise.exe' }
}
$bootstrapper = Join-Path $LayoutPath $bootstrapperName
if (($Action -ne 'Uninstall') -and -not (Test-Path -LiteralPath $bootstrapper)) {
    Stop-Transcript
    throw "Bootstrapper not found: $bootstrapper"
}

# --- Run --------------------------------------------------------------------
try {
    switch ($Action) {
        'Install' {
            $workloadArgs = @()
            foreach ($w in $Workloads) { $workloadArgs += '--add'; $workloadArgs += $w }

            $argList = @(
                '--noWeb', '--passive', '--wait', '--norestart', '--noUpdateInstaller'
            ) + $workloadArgs + @('--includeRecommended')

            $proc = Start-Process -FilePath $bootstrapper -ArgumentList $argList -Wait -PassThru
        }

        'Update' {
            $vs = Get-CimInstance MSFT_VSInstance -Namespace root/cimv2/vs -ErrorAction Stop
            $argList = @(
                '--noWeb', '--update', '--wait', '--passive', '--norestart',
                '--installPath', "`"$($vs.InstallLocation)`""
            )
            $proc = Start-Process -FilePath $bootstrapper -ArgumentList $argList -Wait -PassThru
        }

        'Uninstall' {
            $vs = Get-CimInstance MSFT_VSInstance -Namespace root/cimv2/vs -ErrorAction Stop
            $setupExe = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe'
            if (-not (Test-Path -LiteralPath $setupExe)) {
                throw "VS Installer setup.exe not found at $setupExe"
            }
            $argList = @('uninstall', '--installPath', "`"$($vs.InstallLocation)`"")
            $proc = Start-Process -FilePath $setupExe -ArgumentList $argList -Wait -PassThru
        }
    }

    Write-Host ("Exit code: {0}" -f $proc.ExitCode)
    Stop-Transcript
    exit $proc.ExitCode
}
catch {
    Write-Error $_
    Stop-Transcript
    exit 1
}
