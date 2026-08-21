# Setup OpsVision with Docker Compose
param(
    [switch]$SkipOllama,
    [switch]$SkipMonitoring
)

$ErrorActionPreference = "Stop"

Write-Host "=== OpsVision Docker Compose Setup ===" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker not found. Please install Docker Desktop first."
    exit 1
}
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Error "Docker Compose not found. Please install Docker Compose first."
    exit 1
}
Write-Host "All prerequisites found." -ForegroundColor Green

# Check for GITHUB_API_TOKEN
if (-not $env:GITHUB_API_TOKEN) {
    Write-Host "`nWARNING: GITHUB_API_TOKEN environment variable not set." -ForegroundColor Yellow
    Write-Host "The backend will not be able to access GitHub API without it." -ForegroundColor Yellow
    Write-Host "Set it with: `$env:GITHUB_API_TOKEN = 'your-token'" -ForegroundColor Yellow
}

# Build and start services
Write-Host "`nBuilding and starting OpsVision services..." -ForegroundColor Yellow
$composeFile = Join-Path $PSScriptRoot "..\devops\docker\docker-compose.yml"

docker-compose -f $composeFile up -d --build

# Wait for services to be healthy
Write-Host "`nWaiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Show status
Write-Host "`n=== Service Status ===" -ForegroundColor Cyan
docker-compose -f $composeFile ps

Write-Host "`nOpsVision is running! Access via:" -ForegroundColor Green
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "  Backend API: http://localhost:8080" -ForegroundColor White
Write-Host "  Prometheus: http://localhost:9090" -ForegroundColor White
Write-Host "  Grafana: http://localhost:3001 (admin/admin)" -ForegroundColor White
Write-Host "  OTel Collector: localhost:4317" -ForegroundColor White
Write-Host "  Ollama: http://localhost:11434" -ForegroundColor White

Write-Host "`nTo stop: docker-compose -f $composeFile down" -ForegroundColor Yellow
Write-Host "To view logs: docker-compose -f $composeFile logs -f" -ForegroundColor Yellow