# Common Visual Studio Workload & Component IDs

The canonical lists live in Microsoft Learn:

- [Professional 2022](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-professional?view=vs-2022)
- [Enterprise 2022](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-enterprise?view=vs-2022)
- [Build Tools 2022](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2022)
- [Workload and component IDs (index)](https://learn.microsoft.com/en-us/visualstudio/install/workload-and-component-ids)

The IDs below are a starter set you'll reach for most often. Verify against the
docs above for the version of VS you're packaging — IDs occasionally change
between major releases.

## Workloads (high-level bundles)

| Workload | ID |
|---|---|
| .NET desktop development | `Microsoft.VisualStudio.Workload.ManagedDesktop` |
| ASP.NET and web development | `Microsoft.VisualStudio.Workload.NetWeb` |
| Azure development | `Microsoft.VisualStudio.Workload.Azure` |
| Desktop development with C++ | `Microsoft.VisualStudio.Workload.NativeDesktop` |
| Data storage and processing | `Microsoft.VisualStudio.Workload.Data` |
| Python development | `Microsoft.VisualStudio.Workload.Python` |
| Node.js development | `Microsoft.VisualStudio.Workload.Node` |
| Office/SharePoint development | `Microsoft.VisualStudio.Workload.Office` |
| Data science and analytical applications | `Microsoft.VisualStudio.Workload.DataScience` |
| Game development with Unity | `Microsoft.VisualStudio.Workload.ManagedGame` |
| Game development with C++ | `Microsoft.VisualStudio.Workload.NativeGame` |
| WinUI application development | `Microsoft.VisualStudio.Workload.Universal` |
| Visual Studio extension development | `Microsoft.VisualStudio.Workload.VisualStudioExtension` |
| Visual Studio core editor (always included) | `Microsoft.VisualStudio.Workload.CoreEditor` |

## Common individual components

| Component | ID |
|---|---|
| ASP.NET and web development tools | `Microsoft.VisualStudio.Component.AspNet` |
| .NET Framework 4.8 SDK | `Microsoft.Net.Component.4.8.SDK` |
| .NET Framework 4.8 targeting pack | `Microsoft.Net.Component.4.8.TargetingPack` |
| .NET 8.0 Runtime | `Microsoft.NetCore.Component.Runtime.8.0` |
| Git for Windows | `Microsoft.VisualStudio.Component.Git` |
| GitHub Copilot | `Microsoft.VisualStudio.Component.GitHubCopilot` |
| IntelliCode | `Microsoft.VisualStudio.Component.IntelliCode` |
| Roslyn Compiler | `Microsoft.VisualStudio.Component.Roslyn.Compiler` |
| LINQ to SQL tools | `Microsoft.VisualStudio.Component.LinqToSql` |
| NuGet package manager | `Microsoft.VisualStudio.Component.NuGet` |

## Modifiers

Append `;includeRecommended` or `;includeOptional` to a workload ID on a `--add` line to pull its recommended/optional components in the same call:

```
--add Microsoft.VisualStudio.Workload.Azure;includeRecommended
```

## Discovering IDs from a reference install

If you can't find an ID in the docs, install the workload/component manually on a reference VM, then export the configuration:

1. Open **Visual Studio Installer**.
2. Click **More → Export configuration** on the installed instance.
3. Save the `.vsconfig` file.
4. Open it in any text editor — each component is listed by its full ID.
