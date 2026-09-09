# agentic-infra

Infrastructure that turns any repo in the agentic-boilerplates library into a running service on **Google Cloud Run**, written in **OpenTofu** (Terraform-compatible HCL), with the [agentic-kit](https://github.com/kalpesh122/agentic-kit) built in: one `AGENTS.md` every AI coding agent reads, skills for adding modules and environments, hooks that block destructive commands and refuse to stop on a red `just check`, and a multi-model review council in CI.

What it provisions per environment: enabled APIs, an Artifact Registry repository with cleanup policies, Cloud SQL Postgres 17 (app database, user, password kept in Secret Manager), a Cloud Run v2 service with its own runtime service account, the Cloud SQL connector mounted, secrets injected as environment variables, startup and liveness probes, and **Workload Identity Federation** so GitHub Actions deploy with short-lived tokens and least-privilege rights (push to one repository, deploy one service, act as its runtime account). No service-account keys exist anywhere.

Contract tests run with mocked providers, so `just check` is fully offline and needs no cloud account.

## 60-second quickstart

```bash
git clone https://github.com/kalpesh122/agentic-infra infra && cd infra
just setup && just check                      # offline: fmt + validate + mocked tests

gcloud auth application-default login         # once, on your machine
just bootstrap my-gcp-project-dev             # once per project: remote-state bucket
$EDITOR envs/dev/dev.tfvars envs/dev/backend.hcl
gcloud secrets create api-dev-better-auth-secret --data-file=<(openssl rand -base64 32)
ENV=dev just plan && ENV=dev just apply       # humans apply; agents only plan
just outputs                                  # WIF provider + deployer SA → GitHub secrets
```

Then in the application repo (e.g. agentic-backend-node), add the two values as secrets `WIF_PROVIDER` and `WIF_SERVICE_ACCOUNT` and a deploy job:

```yaml
deploy:
  needs: check
  uses: kalpesh122/agentic-infra/.github/workflows/deploy.yml@main
  with:
    environment: dev
    service: api-dev
    region: asia-south1
    image_repository: asia-south1-docker.pkg.dev/my-gcp-project-dev/api
  secrets:
    workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
    service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
```

Every push to `main` then builds the image, pushes it, deploys, and curls `/health`.

Requirements: [OpenTofu](https://opentofu.org) ≥ 1.8 (Terraform ≥ 1.8 also works), [just](https://github.com/casey/just), gcloud for real applies.

## Commands

| Command | What it does |
|---------|--------------|
| `just setup` | Download providers (no backend) |
| `just lint` / `just fmt` | `tofu fmt -check` + `tofu validate` / format |
| `just test` | `tofu test` with mocked providers |
| `just check` | **Quality gate**: fmt + validate + mocked tests (offline) |
| `just bootstrap <project>` | Create the remote-state bucket (once per project) |
| `ENV=dev just plan` / `just apply` | Plan / apply against a real project |
| `just outputs` | Print the values app repos need as secrets |
| `just council` | Local multi-model code review of your branch |

## Layout

```
main.tf variables.tf outputs.tf   root module composing the pieces per environment
modules/project                    enable APIs
modules/registry                   Artifact Registry + cleanup (keep 20, delete untagged after 7 days)
modules/database                   Cloud SQL Postgres 17, db + user, password in Secret Manager
modules/service                    Cloud Run v2: runtime SA, connector, secrets → env, probes, public invoker
modules/github-oidc                WIF pool/provider scoped to one repo, deployer SA, least-privilege IAM
envs/dev envs/prod                 tfvars (sizing, env vars, secret ids) + backend.hcl
bootstrap/                         remote-state bucket
tests/plan.tftest.hcl              offline contract tests (mock_provider)
.github/workflows/deploy.yml       reusable build → push → deploy → health-check workflow
```

## Design decisions

- **Terraform never owns the image.** CI deploys with `deploy-cloudrun`; `ignore_changes` on the container image keeps `apply` from rolling back a release.
- **Secrets by reference.** tfvars list Secret Manager ids; values are added with `gcloud secrets versions add` and never touch git or state (except the generated DB password, which Terraform creates and stores in Secret Manager).
- **prod is protected.** `deletion_protection`, regional availability, point-in-time recovery, and `min_instances >= 1` are keyed on `environment == "prod"`.
- **Least privilege by construction.** The deployer can push to one repository and deploy one service; the runtime account can read its secrets and connect to its database. Nothing project-wide.

## How AI agents work in this repo

- `AGENTS.md` (≤150 lines) is the map. Skills: `add-module`, `add-environment`, plus the kit's workflow skills. Hooks run `tofu fmt` on edit and `just check` on stop.
- Agents may `plan`; only humans `apply`. The rule is in `AGENTS.md` and `CLAUDE.md`.
- `specs/001-cloud-run-service/` shows the spec → plan → tasks flow; `docs/adr/` records why the stack looks like this.

## Swap-outs

- **AWS / Fly.io**: the module boundaries (registry, database, service, CI identity) map one to one; replace the provider resources inside each module.
- **VPC-only database**: set `ipv4_enabled = false` and add a VPC connector to the service module.
- **Custom domain**: add `google_cloud_run_domain_mapping` or a load balancer in a new module (`add-module` skill).

## License

MIT © Kalpesh Mali
