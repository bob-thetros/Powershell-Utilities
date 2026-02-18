#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Pre-installer script to set up a Windows machine with required software and configurations.
.DESCRIPTION
    This script runs a series of installation and configuration scripts to prepare a Windows machine for use.
    It creates a report file logging the success or failure of each step.
    The script assumes that all child scripts are located in a 'scripts' subdirectory relative to its own location.
    It also ensures that the PowerShell execution policy is set to allow script execution during its run.
.PARAMETER
 None
.EXAMPLE
.\GenerateSelfSigning.ps1
#>
#region Configuration Variables
$CompanyName = "HORIBA"
$date = Get-Date -Format "MM-dd-yyyy-mm"
$scriptPath = "C:\scripts"  # Base path for scripts
$logFilePath = Join-Path $scriptPath "$($env:COMPUTERNAME)-Signing-$date.txt" # Log file path
$ScriptFolder = Join-Path $scriptPath $CompanyName
$Subject  = "CN=$($CompanyName) Local Authenticode Script Signing"
$codeCertificate = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq $Subject}
If (!($codeCertificate))
{
  # Generate a self-signed Authenticode certificate in the local computer's personal certificate store.
  $authenticode = New-SelfSignedCertificate -Subject $Subject -CertStoreLocation Cert:\LocalMachine\My -Type CodeSigningCert
  # Add the self-signed Authenticode certificate to the computer's root certificate store.
  ## Create an object to represent the LocalMachine\Root certificate store.
  $rootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("Root","LocalMachine")
  ## Open the root certificate store for reading and writing.
  $rootStore.Open("ReadWrite")
  ## Add the certificate stored in the $authenticode variable.
  $rootStore.Add($authenticode)
  ## Close the root certificate store.
  $rootStore.Close()
  # Add the self-signed Authenticode certificate to the computer's trusted publishers certificate store.
  ## Create an object to represent the LocalMachine\TrustedPublisher certificate store.
  $publisherStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher","LocalMachine")
  ## Open the TrustedPublisher certificate store for reading and writing.
  $publisherStore.Open("ReadWrite")
  ## Add the certificate stored in the $authenticode variable.
  $publisherStore.Add($authenticode)
  ## Close the TrustedPublisher certificate store.
  $publisherStore.Close()
  # Get the code-signing certificate from the local computer's certificate store with the name $Subject and store it to the $codeCertificate variable.
  $codeCertificate = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq $Subject}
  Write-Host "Selfsign certificate has now been Generated on this system."
}else{
 $codeCertificate = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq $Subject}
	Write-Host "Selfsign already exist on this system."
}
IF(Test-Path $scriptFolder )
{
    Write-Host "Signing all scripts in the $scriptFolder folder."
    Set-AuthenticodeSignature -FilePath "$scriptFolder/*.ps1" -Certificate $codeCertificate 
    Write-Host "Certificate has now been applied to the scripts within the c:\scripts\$($CompanyName) folder."
}
Write-Host "Certificate has now been applied to the scripts within the c:\scripts\$($CompanyName) folder."

# Check if ps1file key exists, create it if not
if (-not (Test-Path "HKLM:\SOFTWARE\Classes\ps1file")) {
    try {
        New-Item -Path "HKLM:\SOFTWARE\Classes\ps1file" | Out-Null  # Create the ps1file key first
        New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\ps1file" -Name "(Default)" -Value ".ps1" -Force | Out-Null # Then create the property
        Write-Host "Created HKLM:\SOFTWARE\Classes\ps1file key and property."
    } catch {
        Write-Warning "Failed to create HKLM:\SOFTWARE\Classes\ps1file key or property. Manual intervention may be required."
    }
}

# Attempt ftype association (with more robust error handling)
try {
    & cmd /c "ftype ps1=powershell.exe -File"
    Write-Host "Associated .ps1 files with PowerShell using ftype."
} catch {
    Write-Warning "Failed to associate .ps1 files with PowerShell using ftype: $($_.Exception.Message)"
}

Write-Host "PS1 scripts associated with powershell (attempted)."
