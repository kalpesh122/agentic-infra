# 0002. Stack choices for the infrastructure boilerplate

Date: 2026-09-09
Status: accepted

## Context

The library's backends ship Dockerfiles but had nowhere to land. The infra layer must be safe for agents to edit (offline gate, no keys, least privilege), cheap for small projects, and honest about what humans must do by hand.

## Decision

OpenTofu with the hashicorp/google provider; Cloud Run v2 + Cloud SQL Postgres 17 + Artifact Registry + Secret Manager; GitHub Actions authenticating through Workload Identity Federation; one root module composed of small modules; dev/prod as tfvars; remote state in GCS created by a bootstrap module; offline contract tests with `mock_provider`; a reusable `workflow_call` deploy workflow.

## Alternatives considered

- **Terraform (HashiCorp)** — the BUSL licence keeps it out of Homebrew core and out of many companies' policies; OpenTofu is MPL, drop-in compatible, and has `mock_provider` for offline tests. The HCL works with either.
- **Pulumi / CDK** — great for teams that want a language; HCL is what most infra reviewers and agents already read.
- **GKE / Kubernetes** — far more surface than an API boilerplate needs; Cloud Run gives scale-to-zero, revisions, and IAM-based identity out of the box.
- **Service-account JSON keys in GitHub secrets** — long-lived credentials; WIF gives short-lived tokens scoped to one repository.
- **Cloud SQL private IP + VPC connector** — more secure and more expensive/complex; the connector over the public IP path with IAM-gated access is the documented starting point, with the swap noted.
- **Terraform managing the running image** — creates fights between CI deploys and applies; CI owns the image.

## Consequences

- Good: `just check` runs in seconds with no cloud; a new environment is two files; app repos deploy with eight lines of YAML.
- Bad: mocked tests prove wiring, not cloud behaviour; the first apply still needs a human with ADC and the bootstrap bucket; Cloud SQL's smallest tier is fine for dev, not prod.
- Neutral: the deploy workflow is opinionated about Cloud Run and Artifact Registry; other clouds need module rewrites.
