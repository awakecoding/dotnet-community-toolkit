# Helper Scripts

This directory contains utility scripts for working with the CommunityToolkit.Mvvm in the RDM project.

**Note:** This toolkit includes disabled (but not deleted) source generators. RDM requires INotifyPropertyChangedGenerator in addition to the actively used generators (ObservablePropertyGenerator, ObservableValidatorValidateAllPropertiesGenerator, RelayCommandGenerator).

## Update-RdmReferences.ps1

Updates all RDM project files to use `ProjectReference` instead of `PackageReference` for CommunityToolkit.Mvvm.

**Usage:**
```powershell
.\scripts\Update-RdmReferences.ps1
```

**Parameters:**
- `RdmPath` - Path to RDM repository (default: `D:\dev\RDM`)
- `ToolkitPath` - Path to dotnet-community-toolkit repository (default: `D:\dev\dotnet-community-toolkit`)

**Example with custom paths:**
```powershell
.\scripts\Update-RdmReferences.ps1 -RdmPath "C:\Projects\RDM" -ToolkitPath "C:\Projects\dotnet-community-toolkit"
```

## Revert-RdmReferences.ps1

Reverts RDM project files back to using `PackageReference` for CommunityToolkit.Mvvm.

**Usage:**
```powershell
.\scripts\Revert-RdmReferences.ps1
```

**Parameters:**
- `RdmPath` - Path to RDM repository (default: `D:\dev\RDM`)
- `NuGetVersion` - Version of CommunityToolkit.Mvvm NuGet package to restore (default: `8.4.0`)

**Example with custom version:**
```powershell
.\scripts\Revert-RdmReferences.ps1 -NuGetVersion "8.5.0"
```

## Workflow

1. **Switch to local development:**
   ```powershell
   .\scripts\Update-RdmReferences.ps1
   ```
   Now when you build RDM, it will automatically build the trimmed toolkit from source.

2. **Make changes to the toolkit:**
   - Edit source files in `src\CommunityToolkit.Mvvm\`
   - Build RDM to test changes: `cd D:\dev\RDM; dotnet build`

3. **Revert to NuGet packages:**
   ```powershell
   .\scripts\Revert-RdmReferences.ps1
   ```
   Useful for comparing behavior or before committing RDM changes.
