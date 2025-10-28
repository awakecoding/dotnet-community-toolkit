# Revert-RdmReferences.ps1
# Reverts RDM project files back to using PackageReference for CommunityToolkit.Mvvm

param(
    [string]$RdmPath = "D:\dev\RDM",
    [string]$NuGetVersion = "8.4.0"
)

Write-Host "Reverting RDM project references to NuGet packages..." -ForegroundColor Cyan
Write-Host "RDM Path: $RdmPath" -ForegroundColor Gray
Write-Host "NuGet Version: $NuGetVersion" -ForegroundColor Gray
Write-Host ""

# Find all .csproj files in RDM
$projectFiles = Get-ChildItem -Path $RdmPath -Filter "*.csproj" -Recurse

$revertedCount = 0

foreach ($file in $projectFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Check if this file has a ProjectReference to CommunityToolkit.Mvvm
    if ($content -match 'ProjectReference.*CommunityToolkit\.Mvvm\.csproj') {
        Write-Host "Reverting: $($file.FullName)" -ForegroundColor Yellow
        
        # Replace ProjectReference with PackageReference
        $packageRef = "<PackageReference Include=`"CommunityToolkit.Mvvm`" Version=`"$NuGetVersion`" />"
        $newContent = $content -replace '<ProjectReference Include="[^"]*CommunityToolkit\.Mvvm\.csproj"[^>]*/>', $packageRef
        
        # Save the updated content
        [System.IO.File]::WriteAllText($file.FullName, $newContent)
        $revertedCount++
    }
}

Write-Host ""
Write-Host "Revert complete! Reverted $revertedCount project(s) back to NuGet." -ForegroundColor Green
