<#
.SYNOPSIS
    SCCM detection script — is the installed VS instance at or above a target version?

.DESCRIPTION
    Use as a detection method on the Update deployment type. Bump $MinVersion
    each time you push a new layout refresh, redeploy the Application, and
    clients will re-evaluate on next policy cycle.

    SCCM detection rules followed:
      - No 'exit' statements
      - Write-Output 'Installed' on success
      - Silent on miss
#>

$MinVersion = [version]'17.10.0'   # <-- bump after each layout refresh

$vs = Get-CimInstance MSFT_VSInstance -Namespace root/cimv2/vs -ErrorAction SilentlyContinue
if ($vs) {
    foreach ($instance in $vs) {
        try {
            if ([version]$instance.Version -ge $MinVersion) {
                Write-Output 'Installed'
                break
            }
        } catch {
            # Version parse failed for this instance; try the next one.
        }
    }
}
