This repository provides a local Trivy scan workflow and a reusable workflow template.

Usage
- To run the scan for this repo, the workflow is available at `.github/workflows/trivy-scan.yml`.
- To call the reusable workflow from another repository in the same org, add a workflow step like:

```yaml
jobs:
  call-trivy:
    uses: <owner>/<repo>/.github/workflows/trivy-scan-reusable.yml@main
    with:
      path: '.'
```

Notes
- I did not change the existing `devops/scanners/trivy.yaml` file; the workflows read it but do not modify it.
- If your `trivy.yaml` requires a specific trivy subcommand or config flag that isn't supported by the generic steps, I can adjust the workflow to honor it.
