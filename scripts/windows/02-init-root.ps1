param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("bootstrap/shared", "bootstrap/dev", "bootstrap/staging", "bootstrap/prod", "platform/dev", "platform/staging", "platform/prod")]
  [string]$Root,

  [Parameter(Mandatory = $true)]
  [string]$StateBucket
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$rootPath = Join-Path $repositoryRoot $Root

if (-not (Test-Path -LiteralPath $rootPath)) {
  throw "Terraform root not found: $rootPath"
}

terraform "-chdir=$rootPath" init -reconfigure -input=false "-backend-config=bucket=$StateBucket"
if ($LASTEXITCODE -ne 0) {
  throw "terraform init failed for $Root"
}

terraform "-chdir=$rootPath" validate
if ($LASTEXITCODE -ne 0) {
  throw "terraform validate failed for $Root"
}

Write-Host "$Root is initialized and valid." -ForegroundColor Green
