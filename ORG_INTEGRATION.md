Org-wide usage and rollout

Goal
- Make the organization use a single reusable Trivy workflow so every repo can call it without changing `devops/scanners/trivy.yaml` in each repo.

Two recommended options

1) Central templates repo (recommended)
- Create a repo in your org (example name: `org-actions` or `.github`) and commit the reusable workflow into `.github/workflows/trivy-scan-reusable.yml`.
- Version the workflow by creating a tag or release (for example `v1`).
- In each target repository add a lightweight workflow that calls the reusable workflow:

Example file to add to other repos: `.github/workflows/call-trivy.yml`

```yaml
name: Trivy (org template)
on: [push, pull_request]

jobs:
  trivy:
    uses: <ORG>/<TEMPLATE_REPO>/.github/workflows/trivy-scan-reusable.yml@v1
    with:
      path: '.'
```

Replace `<ORG>` and `<TEMPLATE_REPO>` with your organization and repo name (for example `myorg/org-actions`).

2) Use this repository as the template source
- If you prefer not to create a separate repo, other repositories can reference the reusable workflow that exists here by replacing `<TEMPLATE_REPO>` with this repo name (`OpsVision-Infrastructure`). Example:

```yaml
uses: <ORG>/OpsVision-Infrastructure/.github/workflows/trivy-scan-reusable.yml@main
```

Rollout helpers

- Manual: add the small `call-trivy.yml` to each repository under `.github/workflows/`.
- Using `gh` CLI (recommended for many repos):

1. Create a local copy of the example file `examples/call-trivy-workflow.yml`.
2. For each repo run (PowerShell):

```powershell
# clone, add file, commit, push
gh repo clone <ORG>/<REPO>
Set-Location <REPO>
mkdir -Force .github\workflows
Copy-Item ..\path\to\call-trivy-workflow.yml .github\workflows\call-trivy.yml
git add .github\workflows\call-trivy.yml
git commit -m "Add org Trivy reusable workflow call"
git push origin HEAD
Set-Location ..
```

Or use `gh api` to create/update contents programmatically (requires a PAT with repo scope or gh auth).

Security and permissions
- Reusable workflows run with permissions of repository that calls them; ensure organization policies allow `actions/checkout` and runners. For sensitive org-wide policies, create process with GitHub admins to approve the template repo and tag releases.

Versioning
- Tag reusable workflows (create a Git tag `v1`) and update calling repos to use that tag so you can safely patch the template in `main` before creating `v2`.

If you want, I can:
- Create a prepared `org-actions` repo layout here (files ready to copy). 
- Generate a script that will push the `call-trivy.yml` to every repo in a provided list (requires your `gh` auth). 
