# Spec: Cloud Run service with database, secrets and GitHub deploys (reference slice)

Status: implemented
Date: 2026-09-09
Owner: Kalpesh Mali

## Problem

The application boilerplates need a production landing zone that an agent can evolve safely: reviewable HCL, an offline gate, no long-lived credentials, and clear human-only steps.

## Goals

- One environment = registry + Postgres + Cloud Run service + CI identity, from one `tfvars` file.
- GitHub Actions deploy through WIF with least privilege.
- Offline contract tests.

## Non-goals

- Multi-region, VPC-only networking, custom domains, GKE.

## Acceptance criteria (testable sentences)

1. `tofu validate` passes for the root and bootstrap modules.
2. `tofu test` with mocked providers passes: dev names resources `api-dev`, prod names `api-prod`, the WIF provider is a full resource name, the database socket URL targets `/cloudsql/<connection_name>`.
3. The deployer service account holds only `artifactregistry.writer` (one repo), `run.developer` (one service) and `iam.serviceAccountUser` (one runtime SA).
4. The runtime service account holds `cloudsql.client` and `secretmanager.secretAccessor` on the referenced secrets only.
5. `prod` enables deletion protection, regional availability and PITR; `dev` does not.
6. The Cloud Run service ignores image changes on apply.
7. `deploy.yml` builds, pushes, deploys and health-checks using WIF inputs only.

## Design

Root module → five modules; outputs expose the URL, image repository, WIF provider and deployer SA.

## Risks and mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Over-broad IAM creeping in | medium | rule in `.claude/rules/hcl.md`; reviewer checks `_iam_member` scope |
| Mocked tests hide provider-side errors | medium | `ENV=dev just plan` required in PRs |

## Open questions

None.
