param(
  [string]$org,
  [string[]]$repos,
  [string]$templatePath = "examples/call-trivy-workflow.yml",
  [string]$branch = "main"
)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "This script requires the GitHub CLI 'gh' to be installed and authenticated."
  exit 1
}

foreach ($r in $repos) {
  $tmp = "$env:TEMP\$r"
  gh repo clone "$org/$r" $tmp
  Set-Location $tmp
  mkdir -Force .github\workflows
  Copy-Item "..\..\$templatePath" .github\workflows\call-trivy.yml -Force
  git add .github\workflows\call-trivy.yml
  git commit -m "Add org Trivy reusable workflow call" -q
  git push origin HEAD:$branch
  Set-Location ..
}
