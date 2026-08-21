# OpsVision Demo - Start stack, post mock data, verify connectivity
param(
    [switch]$SkipOllama,
    [switch]$SkipMonitoring,
    [switch]$Cleanup
)

$ErrorActionPreference = "Stop"

Write-Host "=== OpsVision Demo Script ===" -ForegroundColor Cyan

# If cleanup flag is set, tear down everything
if ($Cleanup) {
    Write-Host "`nCleaning up OpsVision stack (removing volumes)..." -ForegroundColor Yellow
    $composeFile = Join-Path $PSScriptRoot "..\devops\docker\docker-compose.yml"
    docker-compose -f $composeFile down -v
    Write-Host "Cleanup complete. All demo data wiped." -ForegroundColor Green
    exit 0
}

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
    Write-Host "GitHub issue creation and real repo integration will not work." -ForegroundColor Yellow
    Write-Host "Set it with: `$env:GITHUB_API_TOKEN = 'your-token'" -ForegroundColor Yellow
}

# Build and start services
Write-Host "`nBuilding and starting OpsVision services..." -ForegroundColor Yellow
$composeFile = Join-Path $PSScriptRoot "..\devops\docker\docker-compose.yml"

docker-compose -f $composeFile up -d --build

# Wait for services to be ready
Write-Host "`nWaiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Show status
Write-Host "`n=== Service Status ===" -ForegroundColor Cyan
docker-compose -f $composeFile ps

# Verify backend is healthy - poll up to 90 seconds (Spring Boot takes ~45s to start)
Write-Host "`n=== Verifying Backend Health ===" -ForegroundColor Cyan
$backendReady = $false
for ($i = 1; $i -le 9; $i++) {
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -Method Get -TimeoutSec 5
        Write-Host "Backend health: $($health | ConvertTo-Json -Compress)" -ForegroundColor Green
        $backendReady = $true
        break
    } catch {
        Write-Host "Attempt $i/9: Backend not ready yet. Waiting 10 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
}

if (-not $backendReady) {
    Write-Host "Backend still not reachable after 90 seconds. Check docker-compose logs." -ForegroundColor Red
    Write-Host "Run: docker-compose -f devops/docker/docker-compose.yml logs backend" -ForegroundColor Yellow
    exit 1
}

# Post demo data
Write-Host "`n=== Posting Demo Deployment Data ===" -ForegroundColor Cyan

$base = "http://localhost:8080"
$demoDir = Join-Path $PSScriptRoot "..\..\OpsVision-Backend\docs\demo"

# Post ideal deployment
Write-Host "`nPosting ideal deployment (should get DEPLOY)..." -ForegroundColor Yellow
$idealFile = Join-Path $demoDir "analyze-ideal.json"
if (Test-Path $idealFile) {
    $idealBody = Get-Content $idealFile -Raw
    try {
        $idealResult = Invoke-RestMethod -Uri "$base/api/v1/deployments" -Method Post -ContentType "application/json" -Body $idealBody -TimeoutSec 30
        Write-Host "Ideal deployment result:" -ForegroundColor White
        Write-Host ($idealResult | ConvertTo-Json -Depth 5) -ForegroundColor Green
    } catch {
        Write-Host "ERROR posting ideal deployment: $_" -ForegroundColor Red
    }
} else {
    Write-Host "WARNING: $idealFile not found. Skipping." -ForegroundColor Yellow
}

# Post block deployment
Write-Host "`nPosting risky deployment (should get BLOCK)..." -ForegroundColor Yellow
$blockFile = Join-Path $demoDir "analyze-block.json"
if (Test-Path $blockFile) {
    $blockBody = Get-Content $blockFile -Raw
    try {
        $blockResult = Invoke-RestMethod -Uri "$base/api/v1/deployments" -Method Post -ContentType "application/json" -Body $blockBody -TimeoutSec 30
        Write-Host "Risky deployment result:" -ForegroundColor White
        Write-Host ($blockResult | ConvertTo-Json -Depth 5) -ForegroundColor Red
    } catch {
        Write-Host "ERROR posting risky deployment: $_" -ForegroundColor Red
    }
} else {
    Write-Host "WARNING: $blockFile not found. Skipping." -ForegroundColor Yellow
}

# Verify data in backend
Write-Host "`n=== Verifying Deployments in Backend ===" -ForegroundColor Cyan
try {
    $deployments = Invoke-RestMethod -Uri "$base/api/v1/deployments?page=0&size=20" -Method Get -TimeoutSec 10
    Write-Host "Deployments from API:" -ForegroundColor White
    Write-Host ($deployments | ConvertTo-Json -Depth 5) -ForegroundColor Green
} catch {
    Write-Host "ERROR fetching deployments: $_" -ForegroundColor Red
}

# Verify Prometheus
Write-Host "`n=== Verifying Prometheus ===" -ForegroundColor Cyan
try {
    $promTargets = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/targets" -Method Get -TimeoutSec 10
    $upCount = ($promTargets.data.activeTargets | Where-Object { $_.health -eq "up" }).Count
    Write-Host "Prometheus targets UP: $upCount" -ForegroundColor Green
} catch {
    Write-Host "Prometheus not reachable. Check manually at http://localhost:9090/targets" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== Demo Complete ===" -ForegroundColor Cyan
Write-Host "Access the dashboard:" -ForegroundColor Green
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "  Backend API: http://localhost:8080" -ForegroundColor White
Write-Host "  Swagger UI: http://localhost:8080/swagger-ui.html" -ForegroundColor White
Write-Host "  Prometheus: http://localhost:9090" -ForegroundColor White
Write-Host "  Grafana: http://localhost:3001 (admin/admin)" -ForegroundColor White
Write-Host "  OTel Collector: localhost:4317" -ForegroundColor White
Write-Host "  Ollama: http://localhost:11434" -ForegroundColor White

Write-Host "`nTo stop and wipe demo data:" -ForegroundColor Yellow
Write-Host "  .\scripts\run-demo.ps1 -Cleanup" -ForegroundColor White
Write-Host "To stop (keep data):" -ForegroundColor Yellow
Write-Host "  docker-compose -f devops/docker/docker-compose.yml down" -ForegroundColor White