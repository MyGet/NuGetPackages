param($installPath, $toolsPath, $package, $project)

# Ensure we can use the $toolsPath value inside the imported module by making it globally available
$global:nuspecToolsPath = $toolsPath

Import-Module (Join-Path $toolsPath NuSpecTools.psd1)

Write-Host ""
Write-Host "*************************************************************************************"
Write-Host " INSTRUCTIONS"
Write-Host "*************************************************************************************"
Write-Host " - To add a NuSpec to a project use the Install-NuSpec command"
Write-Host " - When using the above command, a .nuspec file will been added to your" 
Write-Host "   project and XSD files will be added to the solution root. Make sure you check it in!"
Write-Host " - For for information, see https://github.com/xavierdecoster/NuGetPackages"
Write-Host "*************************************************************************************"
Write-Host ""