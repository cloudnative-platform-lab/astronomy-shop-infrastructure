param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("dev", "staging", "prod")]
  [string]$Environment,

  [string]$Region = "ap-south-1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$clusterName = "astronomy-shop-$Environment"
aws eks update-kubeconfig --region $Region --name $clusterName --alias $clusterName
if ($LASTEXITCODE -ne 0) {
  throw "Could not update kubeconfig for $clusterName"
}

kubectl get nodes
if ($LASTEXITCODE -ne 0) {
  throw "kubectl cannot reach $clusterName"
}

Write-Host "Connected to $clusterName." -ForegroundColor Green
