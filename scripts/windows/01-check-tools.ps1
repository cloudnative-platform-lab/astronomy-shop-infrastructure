Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$requiredTools = @("aws", "terraform", "kubectl", "helm", "git", "docker", "python")
$missing = @()

foreach ($tool in $requiredTools) {
  if (Get-Command $tool -ErrorAction SilentlyContinue) {
    Write-Host "[OK] $tool"
  }
  else {
    Write-Host "[MISSING] $tool" -ForegroundColor Red
    $missing += $tool
  }
}

if ($missing.Count -gt 0) {
  throw "Install the missing tools before continuing: $($missing -join ', ')"
}

Write-Host "`nAWS identity currently selected:"
aws sts get-caller-identity

Write-Host "`nAll required tools are available." -ForegroundColor Green
