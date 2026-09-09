---
name: add-environment
description: Add a new environment (e.g. staging) as tfvars + backend config + CI environment, keeping prod protections intact. Use when a new deployment target is needed.
argument-hint: [env-name]
---

# Add an environment

1. Extend the `environment` validation in `variables.tf` and any `var.environment == "prod"` conditionals that should also apply (or not) to the new env.
2. `envs/<env>/<env>.tfvars`: project id, region, sizing, env vars, secret ids. `envs/<env>/backend.hcl`: bucket + prefix.
3. Create the state bucket once: `just bootstrap <project>`; create the secrets referenced in tfvars with `gcloud secrets create`.
4. Add a `run` block in `tests/plan.tftest.hcl` with `variables { environment = "<env>" }` asserting naming.
5. In app repos, add a GitHub `environment` with the two WIF secrets from `just outputs`, and a job that `uses:` `deploy.yml` with the new env.
6. `just check`; `ENV=<env> just plan`.
