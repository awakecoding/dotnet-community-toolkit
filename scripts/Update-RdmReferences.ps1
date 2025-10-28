# Update-RdmReferences.ps1
# Updates RDM project files to use local NuGet package instead of official release for CommunityToolkit.Mvvm

param(
    [string]$RdmPath = "D:\dev\RDM",
    [string]$ToolkitPath = "D:\dev\dotnet-community-toolkit",
    [string]$LocalNuGetPath = "D:\local-nuget"
)

Write-Host "Updating RDM to use local CommunityToolkit.Mvvm package..." -ForegroundColor Cyan
Write-Host "RDM Path: $RdmPath" -ForegroundColor Gray
Write-Host "Toolkit Path: $ToolkitPath" -ForegroundColor Gray
Write-Host "Local NuGet Path: $LocalNuGetPath" -ForegroundColor Gray
Write-Host ""

# Step 1: Build the toolkit
Write-Host "Building CommunityToolkit.Mvvm..." -ForegroundColor Yellow
$buildResult = & dotnet build "$ToolkitPath\src\CommunityToolkit.Mvvm\CommunityToolkit.Mvvm.csproj" -c Debug -v:minimal 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    Write-Host $buildResult
    exit 1
}

# Step 2: Pack into NuGet package
Write-Host "Packing into NuGet package..." -ForegroundColor Yellow
$packResult = & dotnet pack "$ToolkitPath\src\CommunityToolkit.Mvvm\CommunityToolkit.Mvvm.csproj" -c Debug -o $LocalNuGetPath --no-build 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Host "Pack failed!" -ForegroundColor Red
    Write-Host $packResult
    exit 1
}

# Step 3: Get the package version
$nupkg = Get-ChildItem -Path $LocalNuGetPath -Filter "CommunityToolkit.Mvvm.*.nupkg" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (!$nupkg) {
    Write-Host "Could not find the NuGet package!" -ForegroundColor Red
    exit 1
}

$packageVersion = $nupkg.Name -replace 'CommunityToolkit\.Mvvm\.(.*)\.nupkg', '$1'
Write-Host "Package version: $packageVersion" -ForegroundColor Green
Write-Host ""

# Step 4: Update NuGet.config to include local feed
$nugetConfigPath = Join-Path $RdmPath "NuGet.config"
if (Test-Path $nugetConfigPath) {
    [xml]$nugetConfig = Get-Content $nugetConfigPath
    $packageSources = $nugetConfig.configuration.packageSources
    $localSource = $packageSources.add | Where-Object { $_.key -eq "local-toolkit" }
    
    if (!$localSource) {
        Write-Host "Adding local-toolkit source to NuGet.config..." -ForegroundColor Yellow
        $newSource = $nugetConfig.CreateElement("add")
        $newSource.SetAttribute("key", "local-toolkit")
        $newSource.SetAttribute("value", $LocalNuGetPath)
        $packageSources.AppendChild($newSource) | Out-Null
        $nugetConfig.Save($nugetConfigPath)
    }
} else {
    Write-Host "Creating NuGet.config with local source..." -ForegroundColor Yellow
    $nugetConfigContent = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
    <add key="local-toolkit" value="$LocalNuGetPath" />
  </packageSources>
</configuration>
"@
    Set-Content -Path $nugetConfigPath -Value $nugetConfigContent
}

# Step 5: Update project files to use the local package version
Write-Host "Updating project references..." -ForegroundColor Yellow
$projectFiles = Get-ChildItem -Path $RdmPath -Filter "*.csproj" -Recurse
$updatedCount = 0

foreach ($file in $projectFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Replace ProjectReference with PackageReference
    if ($content -match 'ProjectReference.*CommunityToolkit\.Mvvm\.csproj') {
        Write-Host "  Updating: $($file.FullName)" -ForegroundColor Gray
        $content = $content -replace '<ProjectReference Include="[^"]*CommunityToolkit\.Mvvm\.csproj"[^>]*/>', "<PackageReference Include=`"CommunityToolkit.Mvvm`" Version=`"$packageVersion`" />"
        [System.IO.File]::WriteAllText($file.FullName, $content)
        $updatedCount++
    }
    # Update existing PackageReference version
    elseif ($content -match 'PackageReference Include="CommunityToolkit\.Mvvm"') {
        Write-Host "  Updating: $($file.FullName)" -ForegroundColor Gray
        $content = $content -replace '(<PackageReference Include="CommunityToolkit\.Mvvm" Version=")[^"]*(")', "`${1}$packageVersion`$2"
        [System.IO.File]::WriteAllText($file.FullName, $content)
        $updatedCount++
    }
}

Write-Host ""
Write-Host "Update complete! Updated $updatedCount project(s) to version $packageVersion" -ForegroundColor Green
Write-Host ""
Write-Host "To revert back to official NuGet packages, use: Revert-RdmReferences.ps1" -ForegroundColor Cyan
