$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path $MyInvocation.MyCommand.Definition

$packageArgs = @{
  packageName    = 'audacity'
  fileType       = 'msi'
  file           = "$toolsDir\audacity-win-4.0.2-x86_64.msi"
  file64         = "$toolsDir\audacity-win-4.0.2-x86_64.msi"
  silentArgs     = '/qn /norestart'
  validExitCodes = @(0, 1223, 3010)
}

# For MSI installers, use Install-ChocolateyInstallPackage
# For version 4.0+, 32-bit is not supported, both file and file64 point to x86_64 (64-bit Intel/AMD)
Install-ChocolateyInstallPackage @packageArgs

# Clean up downloaded installers
Get-ChildItem "$toolsDir\*.$($packageArgs.fileType)" | ForEach-Object {
  Remove-Item $_ -ea 0
  if (Test-Path $_) {
    Set-Content "$_.ignore"
  }
}

$packageName = $packageArgs.packageName

# Audacity 4.0+ installs to "Audacity 4" directory and registers as "Audacity 4.0"
# Try multiple patterns to find the installation
$installLocation = Get-AppInstallLocation $packageName
if (-not $installLocation) {
  $installLocation = Get-AppInstallLocation "Audacity 4*"
}

if ($installLocation) {
  Write-Host "$packageName installed to '$installLocation'"
  
  # Find the Audacity executable (could be Audacity.exe or Audacity4.exe in bin folder)
  $exePaths = @(
    "$installLocation\bin\Audacity4.exe",
    "$installLocation\bin\Audacity.exe",
    "$installLocation\Audacity.exe",
    "$installLocation\$packageName.exe"
  )
  
  $exePath = $exePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
  
  if ($exePath) {
    Register-Application $exePath
    Write-Host "Registered application: $exePath"
  }
  else {
    Write-Warning "Audacity executable not found in expected locations"
  }
}
else { 
  Write-Warning "Can't find $packageName install location" 
}
