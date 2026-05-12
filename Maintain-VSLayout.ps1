<#
.SYNOPSIS
    Wrapper for the Visual Studio bootstrapper's layout-maintenance operations.

.DESCRIPTION
    Runs --layout (update), --verify, --fix, or --clean against an existing
    layout. The "update" operation re-runs the layout against its layout.json
    to pull current package versions; the others are integrity / cleanup ops.

    Recommended pattern: update to a local staging path, verify, then robocopy
    the staged tree onto the production share. Don't update directly over UNC.

.PARAMETER Operation
    Update  - re-pull latest packages for everything in layout.json
    Verify  - check the layout for missing or corrupt files (read-only)
    Fix     - verify + redownload bad files (needs internet)
    Clean   - remove old cached packages no longer referenced by the catalog

.PARAMETER Edition
    Professional or Enterprise. Determines which bootstrapper inside the
    layout root is launched.

.PARAMETER LayoutPath
    Path to the layout (local or UNC).

.PARAMETER Language
    Layout language (default en-US).

.PARAMETER CatalogPath
    For Operation=Clean only. Path to the Archive\<GUID>\Catalog.json that
    defines the "current" set of packages. Old packages not referenced there
    will be removed.

.EXAMPLE
    .\Maintain-VSLayout.ps1 -Operation Update -Edition Professional `
        -LayoutPath 'C:\Temp\VSLayout-Staging'

.EXAMPLE
    .\Maintain-VSLayout.ps1 -Operation Verify -Edition Professional `
        -LayoutPath '\\fileshare\Sources\VisualStudio\2022\Pro\VSLayout'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Update','Verify','Fix','Clean')]
    [string]$Operation,

    [Parameter(Mandatory)][ValidateSet('Professional','Enterprise')]
    [string]$Edition,

    [Parameter(Mandatory)]
    [string]$LayoutPath,

    [string]$Language = 'en-US',

    [string]$CatalogPath
)

$ErrorActionPreference = 'Stop'

$bootstrapperName = switch ($Edition) {
    'Professional' { 'vs_professional.exe' }
    'Enterprise'   { 'vs_enterprise.exe' }
}
$bootstrapper = Join-Path $LayoutPath $bootstrapperName
if (-not (Test-Path -LiteralPath $bootstrapper)) {
    throw "Bootstrapper not found: $bootstrapper"
}

$argList = switch ($Operation) {
    'Update' {
        @('--layout', "`"$LayoutPath`"", '--lang', $Language, '--passive', '--wait')
    }
    'Verify' {
        @('--layout', "`"$LayoutPath`"", '--verify')
    }
    'Fix' {
        @('--layout', "`"$LayoutPath`"", '--fix')
    }
    'Clean' {
        if (-not $CatalogPath) {
            throw "-CatalogPath is required for Operation=Clean (path to the Archive\<GUID>\Catalog.json)."
        }
        @('--layout', "`"$LayoutPath`"", '--clean', "`"$CatalogPath`"")
    }
}

Write-Host "Operation=$Operation Edition=$Edition"
Write-Host "LayoutPath=$LayoutPath"
Write-Host ("Args: {0}" -f ($argList -join ' '))

$proc = Start-Process -FilePath $bootstrapper -ArgumentList $argList -Wait -PassThru
Write-Host ("Exit code: {0}" -f $proc.ExitCode)
exit $proc.ExitCode
