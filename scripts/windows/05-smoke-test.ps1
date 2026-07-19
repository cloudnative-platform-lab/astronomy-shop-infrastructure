param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("dev", "staging", "prod")]
  [string]$Environment
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Waiting for all application pods in namespace $Environment..."
kubectl wait --namespace $Environment --for=condition=Ready pod --all --timeout=10m
if ($LASTEXITCODE -ne 0) {
  kubectl get pods --namespace $Environment
  kubectl get events --namespace $Environment --sort-by=.lastTimestamp
  throw "One or more pods did not become Ready."
}

kubectl get applications --namespace argocd
kubectl get deployments,rollouts.argoproj.io --namespace $Environment
kubectl get pods,services,hpa --namespace $Environment

if ($Environment -ne "dev") {
  kubectl get servicemonitors.monitoring.coreos.com --namespace $Environment
}

Write-Host "Smoke test passed. Use port-forward to perform the browser test." -ForegroundColor Green
