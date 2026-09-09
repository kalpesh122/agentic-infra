# Tasks: Cloud Run service

- [x] APIs + Artifact Registry with cleanup policies — proof: `tofu validate`
- [x] Cloud SQL Postgres 17 + Secret Manager password — proof: `run "dev_is_small_and_not_protected"` socket URL assertion
- [x] Cloud Run v2 service, runtime SA, connector, probes — proof: naming assertions in `tests/plan.tftest.hcl`
- [x] WIF pool/provider + least-privilege deployer — proof: `run "oidc_is_scoped_to_the_repository"`
- [x] dev/prod tfvars, backend configs, bootstrap bucket, reusable deploy workflow
- [x] Docs / README / ADR updated
- [x] `just check` green (offline)
