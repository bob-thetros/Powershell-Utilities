<#
.SYNOPSIS
Comprensive upgrade of applications on system to the latest release per vendor
.DESCRIPTION
Comprensive upgrade of applications on system to the latest release per vendor
.PARAMETER none
none
.EXAMPLE
C:\> .\Online-Update-AllApps.ps1
#>
Install-PackageProvider -Name "NuGet" -Force
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Script winget-install -Force
winget-install
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
