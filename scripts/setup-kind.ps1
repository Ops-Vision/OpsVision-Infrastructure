# Setup OpsVision on Kind cluster
param(
    [string]$ClusterName = "opsvision-cluster",
    [switch]$SkipIngress
)

$ErrorActionPreference = "Stop"

Write-Host "=== OpsVision Kind Cluster Setup ===" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow
$tools = @("kind", "kubectl", "docker")
foreach ($tool in $tools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Error "Required tool '$tool' not found. Please install it first."
        exit 1
    }
}
Write-Host "All prerequisites found." -ForegroundColor Green

# Create cluster
Write-Host "`nCreating Kind cluster '$ClusterName'..." -ForegroundColor Yellow
$configPath = Join-Path $PSScriptRoot "..\devops\kubernetes\kind-config.yaml"
kind create cluster --name $ClusterName --config $configPath
Write-Host "Cluster created." -ForegroundColor Green

# Set kubectl context
kubectl config use-context "kind-$ClusterName"

# Install NGINX Ingress Controller
if (-not $SkipIngress) {
    Write-Host "`nInstalling NGINX Ingress Controller..." -ForegroundColor Yellow
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
    Write-Host "Ingress controller installed." -ForegroundColor Green
}

# Apply OpsVision manifests
Write-Host "`nDeploying OpsVision application..." -ForegroundColor Yellow
$k8sDir = Join-Path $PSScriptRoot "..\devops\kubernetes"

kubectl apply -f (Join-Path $k8sDir "namespace.yaml")
kubectl apply -f (Join-Path $k8sDir "secrets.yaml")
kubectl apply -f (Join-Path $k8sDir "postgres-deployment.yaml")
kubectl apply -f (Join-Path $k8sDir "backend-deployment.yaml")
kubectl apply -f (Join-Path $k8sDir "frontend-deployment.yaml")
kubectl apply -f (Join-Path $k8sDir "ingress.yaml")

# Wait for deployments
Write-Host "`nWaiting for deployments to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/opsvision-backend -n opsvision --timeout=120s
kubectl rollout status deployment/opsvision-frontend -n opsvision --timeout=120s

# Show status
Write-Host "`n=== Deployment Status ===" -ForegroundColor Cyan
kubectl get all -n opsvision
kubectl get ingress -n opsvision

Write-Host "`nOpsVision is deployed! Access via:" -ForegroundColor Green
Write-Host "  Frontend: http://opsvision.local" -ForegroundColor White
Write-Host "  Backend API: http://opsvision.local/api" -ForegroundColor White
Write-Host "`nAdd '127.0.0.1 opsvision.local' to your hosts file if needed." -ForegroundColor Yellow