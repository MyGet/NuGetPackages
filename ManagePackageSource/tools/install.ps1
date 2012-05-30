param($installPath, $toolsPath, $package, $project)
Import-Module (Join-Path $toolsPath ManagePackageSources.psd1)

Write-Host ""
Write-Host "*************************************************************************************"
Write-Host "Congratulations! The following additional commands have been installed into your"
Write-Host "Visual Studio PowerShell Console:"
Write-Host "- Get-PackageSource"
Write-Host "- Add-PackageSource"
Write-Host "- Remove-PackageSource"
Write-Host "- Set-ActivePackageSource"
Write-Host "*************************************************************************************"
Write-Host ""