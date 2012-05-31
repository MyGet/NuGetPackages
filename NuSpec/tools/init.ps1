param($installPath, $toolsPath, $package, $project)

# Configure
$moduleName = "NuSpec"

# Derived variables
$psdFileName = "$moduleName.psd1"
$psmFileName = "$moduleName.psm1"
$psd = (Join-Path $toolsPath $psdFileName)
$psm = (Join-Path $toolsPath $psmFileName)

# Check if the NuGet_profile.ps1 exists and register the NuSpec.psd1 module
if(!(Test-Path $profile)){
	mkdir -force (Split-Path $profile)
	New-Item $profile -Type file -Value "Import-Module $moduleName -DisableNameChecking"
}
else{
	Add-Content -Path $profile -Value "`r`nImport-Module $moduleName -DisableNameChecking"
}

# Copy the files to the module in the profile directory
$profileDirectory = Split-Path $profile -parent
$profileModulesDirectory = (Join-Path $profileDirectory "Modules")
$moduleDir = (Join-Path $profileModulesDirectory $moduleName)
if(!(Test-Path $moduleDir)){
	mkdir -force $moduleDir
}
copy $psd (Join-Path $moduleDir $psdFileName)
copy $psm (Join-Path $moduleDir $psmFileName)

# Copy additional files
copy (Join-Path $toolsPath "NuGet.Extensions.targets") (Join-Path $moduleDir "NuGet.Extensions.targets")
copy "$toolsPath\*.xsd" $moduleDir
copy "$toolsPath\*.xml" $moduleDir
$msbuildExtPackDir = (Join-Path $moduleDir "MSBuildExtensionPack")
if(!(Test-Path $msbuildExtPackDir)){
	mkdir -force $msbuildExtPackDir
}
copy "$toolsPath\MSBuildExtensionPack\*.*" $msbuildExtPackDir

# Reload NuGet PowerShell profile
. $profile

Write-Host ""
Write-Host "*************************************************************************************"
Write-Host " INSTRUCTIONS"
Write-Host "*************************************************************************************"
Write-Host " - This package relies on NuGet package restore, so enable it first"
Write-Host " - To add a NuSpec to a project use the Install-NuSpec command"
Write-Host " - When using the above command, a .nuspec file will been added to your" 
Write-Host "   project and XSD files will be added to the solution root. Make sure you check it in!"
Write-Host " - Other available cmdlets are: Enable-PackagePush"
Write-Host " - For for information, see https://github.com/myget/NuGetPackages"
Write-Host "*************************************************************************************"
Write-Host ""