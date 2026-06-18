try {
  if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    $ErrorActionPreference = 'Stop'
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
      Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    Install-Module ImportExcel -Scope CurrentUser -Force -AllowClobber
  }
  Import-Module ImportExcel
  Write-Host "ImportExcel ready: $((Get-Module ImportExcel).Version)"
} catch {
  Write-Host ("INSTALL FAILED: " + $_.Exception.Message)
}
