---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.tftest.hcl"
---

# HCL rules

- Variables: `type` + `description`, validation for enums. Outputs: `description` on anything an app repo consumes.
- Naming: `${service}-${environment}` for every resource that is per environment.
- IAM: `_iam_member` resources only; roles as narrow as GCP allows; members are service accounts.
- Secrets: reference secret ids; never `secret_data` from a variable in the root module.
- Images are deployed by CI; keep `ignore_changes` on the container image.
- Every behaviour change gets a mocked `run` block in `tests/plan.tftest.hcl`.
