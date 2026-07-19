param(
  [Parameter(Mandatory = $true)]
  [string]$PrivateKeyPath,

  [string]$RepositoryUrl = "git@github.com:cloudnative-platform-lab/astronomy-shop-gitops.git"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedKey = Resolve-Path -LiteralPath $PrivateKeyPath

$secretYaml = kubectl create secret generic astronomy-shop-gitops-repository `
  --namespace argocd `
  --from-literal=type=git `
  --from-literal="url=$RepositoryUrl" `
  --from-file="sshPrivateKey=$resolvedKey" `
  --dry-run=client `
  --output=yaml

if ($LASTEXITCODE -ne 0) {
  throw "Could not build the Argo CD repository Secret."
}

$secretYaml | kubectl apply -f - | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Could not apply the Argo CD repository Secret."
}

kubectl label secret astronomy-shop-gitops-repository `
  --namespace argocd `
  argocd.argoproj.io/secret-type=repository `
  --overwrite | Out-Null

Write-Host "Argo CD repository credential configured without writing the private key to Git or Terraform state." -ForegroundColor Green
