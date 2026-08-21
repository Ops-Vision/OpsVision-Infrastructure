# Run all security scanners locally
param(
    [switch]$SkipTrivy,
    [switch]$SkipSemgrep,
    [switch]$SkipSonar,
    [switch]$SkipDependencyCheck
)

$ErrorActionPreference = "Stop"

Write-Host "=== OpsVision Security Scanners ===" -ForegroundColor Cyan

# Trivy
if (-not $SkipTrivy) {
    Write-Host "`n[1/4] Running Trivy vulnerability scan..." -ForegroundColor Yellow
    if (Get-Command trivy -ErrorAction SilentlyContinue) {
        trivy fs --severity HIGH,CRITICAL --format table .
    } else {
        Write-Host "Trivy not installed. Skipping..." -ForegroundColor Red
    }
}

# Semgrep
if (-not $SkipSemgrep) {
    Write-Host "`n[2/4] Running Semgrep SAST scan..." -ForegroundColor Yellow
    if (Get-Command semgrep -ErrorAction SilentlyContinue) {
        semgrep scan --config p/security-audit --config p/owasp-top-ten --config p/java --config p/javascript .
    } else {
        Write-Host "Semgrep not installed. Skipping..." -ForegroundColor Red
    }
}

# SonarQube
if (-not $SkipSonar) {
    Write-Host "`n[3/4] Running SonarQube analysis..." -ForegroundColor Yellow
    if (Get-Command sonar-scanner -ErrorAction SilentlyContinue) {
        sonar-scanner -Dproject.settings=devops/scanners/sonar-project.properties
    } else {
        Write-Host "sonar-scanner not installed. Skipping..." -ForegroundColor Red
    }
}

# OWASP Dependency Check
if (-not $SkipDependencyCheck) {
    Write-Host "`n[4/4] Running OWASP Dependency Check..." -ForegroundColor Yellow
    if (Test-Path "backend/pom.xml") {
        Push-Location backend
        mvn org.owasp:dependency-check-maven:check -DfailBuildOnCVSS=7
        Pop-Location
    } else {
        Write-Host "backend/pom.xml not found. Skipping..." -ForegroundColor Red
    }
}

Write-Host "`n=== Scanner run complete ===" -ForegroundColor Green