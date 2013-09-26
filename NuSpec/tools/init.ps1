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
else {
    if(!(Get-Content $profile | Select-String "Import-Module $moduleName" -quiet)){
	    Add-Content -Path $profile -Value "`r`nImport-Module $moduleName -DisableNameChecking"
    }
}

# Copy the files to the module in the profile directory
$profileDirectory = Split-Path $profile -parent
$profileModulesDirectory = (Join-Path $profileDirectory "Modules")
$moduleDir = (Join-Path $profileModulesDirectory $moduleName)
if(Test-Path $moduleDir){
    # If you install this package and the dir exists, then you're upgrading...
    Remove-Item -Recurse -Force $moduleDir
}
if(!(Test-Path $moduleDir)){
	mkdir -force $moduleDir
}
copy $psd (Join-Path $moduleDir $psdFileName)
copy $psm (Join-Path $moduleDir $psmFileName)

# Copy additional files
copy "$toolsPath\*.xsd" $moduleDir
copy "$toolsPath\*.xml" $moduleDir

# Reload NuGet PowerShell profile
. $profile

Write-Host ""
Write-Host "*************************************************************************************"
Write-Host " INSTRUCTIONS"
Write-Host "*************************************************************************************"
Write-Host " To create a NuSpec for a project use the Install-NuSpec command"
Write-Host " By default, the target project selected in the NuGet Package Manager Console is used"
Write-Host ""
Write-Host " Additional options:"
Write-Host " -ProjectName <projectA|projectB> [An array of projectnames; use TAB-completion]"
Write-Host " -Template <templatePath> [Choose a custom nuspec template]"
Write-Host " -EnableIntelliSense [using the latest (unofficial) nuspec.xsd]"
Write-Host ""
Write-Host " For for information, see https://github.com/myget/NuGetPackages"
Write-Host "*************************************************************************************"
Write-Host ""