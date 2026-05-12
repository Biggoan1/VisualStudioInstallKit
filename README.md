# VisualStudioInstallKit

PowerShell scripts and detection-method templates for deploying Visual Studio Professional or Enterprise through Microsoft Configuration Manager (SCCM/MECM) using an offline layout. Drop-in starter kit for the install, the updater, add-ins, and the detection methods that hold the whole thing together.

> **Walkthrough**: [Deploying Visual Studio via SCCM: Layout, Updater, and Add-ins](https://bits-n-bytes.org/blog/deploying-visual-studio-via-sccm/) — companion blog post explaining how the pieces fit together.

## What's in the kit

| File | Purpose |
|---|---|
| `Install-VS.ps1` | Install / Update / Uninstall VS, parameterized by `-Action` and `-Edition`. |
| `Install-VSAddOn.ps1` | Add / remove a single VS workload component (add-in) by `-ComponentId`. |
| `Maintain-VSLayout.ps1` | Wrapper for layout maintenance (`--layout` update, `--verify`, `--fix`, `--clean`). |
| `Detection/Detect-VSInstalled.ps1` | Detection method for the base install — checks edition Caption. |
| `Detection/Detect-VSAtLeastVersion.ps1` | Detection method for the updater — checks Version ≥ a target. |
| `Detection/Detect-VSComponent.ps1` | Detection method for an add-in — `vswhere -requires <ComponentId>`. |
| `Examples/Common-WorkloadIds.md` | Quick reference for the workload / component IDs you reach for most. |
| `Examples/Response-template.json` | Template for the layout's `Response.json` (only `channelUri` typically needs editing). |

## Prerequisites

- An offline Visual Studio layout on a UNC share. See the [companion blog post](https://bits-n-bytes.org/blog/deploying-visual-studio-via-sccm/#create-the-layout) or [Microsoft's docs on creating a network installation](https://learn.microsoft.com/en-us/visualstudio/install/create-a-network-installation-of-visual-studio).
- SCCM / MECM with the ConfigurationManager PowerShell module on the admin box (only needed for creating the Applications; the scripts themselves run on clients).
- Endpoint with the SCCM client and access to the layout share.

## Quick start — one edition, end to end

1. **Build the layout** (one-time, plus periodic refresh).
   ```powershell
   .\vs_professional.exe --layout 'C:\Temp\VSLayout-Staging' `
       --add Microsoft.VisualStudio.Workload.ManagedDesktop `
       --includeRecommended --lang en-US --passive --wait
   robocopy 'C:\Temp\VSLayout-Staging' '\\<share>\Sources\VisualStudio\2022\Pro\VSLayout' /e /mt:16
   ```

2. **Pin the layout's `Response.json`** so clients update from your share, not Microsoft's CDN. Open `\\<share>\...\VSLayout\Response.json` and set `channelUri` to your UNC path (backslashes doubled — JSON escaping). See `Examples/Response-template.json`.

3. **Create the SCCM Applications**, each pointing at the layout as content source:

   | Application | Install command | Detection script |
   |---|---|---|
   | Visual Studio Professional 2022 | `powershell.exe -ExecutionPolicy Bypass -File Install-VS.ps1 -Action Install -Edition Professional -LayoutPath '\\<share>\...\VSLayout'` | `Detect-VSInstalled.ps1` (edit `$TargetCaption`) |
   | Visual Studio Update | `powershell.exe -ExecutionPolicy Bypass -File Install-VS.ps1 -Action Update -Edition Professional -LayoutPath '\\<share>\...\VSLayout'` | `Detect-VSAtLeastVersion.ps1` (edit `$MinVersion`) |
   | VS Add-on: ASP.NET | `powershell.exe -ExecutionPolicy Bypass -File Install-VSAddOn.ps1 -Action Install -ComponentId Microsoft.VisualStudio.Component.AspNet -LayoutPath '\\<share>\...\VSLayout'` | `Detect-VSComponent.ps1` (edit `$ComponentId`) |

4. **Deployment type settings** for all three:
   - Installation behavior: `InstallForSystem`
   - Logon requirement: `WhetherOrNotUserLoggedOn`
   - Maximum runtime: `120` minutes
   - Exit codes: `0`, `3010`, `1641` = success (3010 and 1641 = soft reboot required)

## Common workload / component IDs

See [`Examples/Common-WorkloadIds.md`](./Examples/Common-WorkloadIds.md). The canonical list lives at [Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/install/workload-and-component-ids).

To find an ID for a component you can't locate in the docs: install it on a reference VM, then **Visual Studio Installer → More → Export configuration**. The exported `.vsconfig` file lists every component on the instance by full ID.

## Layout maintenance

Run on Patch Tuesday — stage to local disk, verify, mirror to the share:

```powershell
.\Maintain-VSLayout.ps1 -Operation Update -Edition Professional `
    -LayoutPath 'C:\Temp\VSLayout-Staging'

.\Maintain-VSLayout.ps1 -Operation Verify -Edition Professional `
    -LayoutPath 'C:\Temp\VSLayout-Staging'

robocopy 'C:\Temp\VSLayout-Staging' '\\<share>\...\VSLayout' /mir /mt:16
```

After mirroring, bump `$MinVersion` in `Detection/Detect-VSAtLeastVersion.ps1` to the layout's new version and redeploy the Update Application. Clients re-evaluate on next policy cycle.

## SCCM detection-method rules followed

All three detection scripts in `Detection/` follow the SCCM rules:

- **No `exit` statements.** SCCM treats any `exit` as an error.
- **`Write-Output 'Installed'` on success.** Not `Write-Host`.
- **Silent on miss.** No output means not installed.
- Version comparisons use `-ge` so a newer version satisfies the older deployment's detection.

## Editing for your environment

Each script accepts paths as parameters — nothing is hardcoded to a specific share. The three detection-script templates have a clearly-marked variable at the top (`$TargetCaption`, `$MinVersion`, `$ComponentId`) that you edit per deployment.

## License

MIT — see [`LICENSE`](./LICENSE).
