# AGENTS.md

Single source of truth for every AI coding agent in this repository. `CLAUDE.md` imports it; `GEMINI.md`
and `.github/copilot-instructions.md` link to it. Keep it under 150 lines: a map, not an encyclopedia.

## What this repository is

Infrastructure for running any of the agentic backends on **Google Cloud Run** with **OpenTofu** (Terraform-
compatible HCL): Artifact Registry, Cloud SQL Postgres 17, Secret Manager, a Cloud Run v2 service with a
dedicated runtime service account, and **GitHub Actions → Workload Identity Federation** (no long-lived keys)
with least-privilege deploy rights. A reusable `deploy.yml` workflow builds, pushes, deploys and health-checks an
app image. Environments are `dev` and `prod` tfvars over the same modules; remote state lives in a GCS bucket
created by `bootstrap/`. Contract tests run offline with **mocked providers**, so `just check` needs no cloud.

## Command surface

| Command | What it does |
|---------|--------------|
| `just setup` | `tofu init -backend=false` for root and bootstrap (downloads providers) |
| `just lint` / `just fmt` | `tofu fmt -check` + `tofu validate` / format |
| `just test` | `tofu test` with mocked providers (`tests/*.tftest.hcl`) |
| `just check` | **The gate**: fmt + validate + tests, fully offline |
| `just bootstrap <project>` | One-time: create the remote-state bucket |
| `ENV=dev just plan` / `just apply` | Plan/apply against the real project (needs `gcloud auth application-default login`) |
| `just outputs` | Print `workload_identity_provider` and `deployer_service_account` for app-repo secrets |
| `just council` | Local multi-model code review vs main |

## Layout

```
versions.tf providers.tf variables.tf main.tf outputs.tf   root module: composes the modules per environment
modules/project/       enable APIs
modules/registry/      Artifact Registry repo + cleanup policies
modules/database/      Cloud SQL Postgres 17, app db/user, password in Secret Manager, socket URL output
modules/service/       Cloud Run v2 service, runtime SA, Cloud SQL connector, secrets → env, probes, public invoker
modules/github-oidc/   WIF pool/provider scoped to one repo, deployer SA, least-privilege IAM
envs/{dev,prod}/       <env>.tfvars (sizing, names, env vars, secret ids) + backend.hcl (state bucket/prefix)
bootstrap/             the state bucket (run once per project)
tests/plan.tftest.hcl  offline contract tests (mock_provider google/random)
.github/workflows/     ci.yml (just check) · deploy.yml (reusable workflow_call for app repos)
```

## Workflow (non-negotiable)

1. Non-trivial change → `brainstorm-spec` skill first (`specs/NNN-slug/`).
2. New resource kind → `add-module` skill. New environment → `add-environment` skill.
3. Add or update a `run` block in `tests/plan.tftest.hcl` for every behaviour you add (mocked, offline).
4. `just check` green before "done"; then `ENV=dev just plan` and paste the plan summary in the PR.
5. Conventional commits; `just council` before pushing anything non-trivial.

## Hard rules

- No secrets in HCL, tfvars or git. Secret *ids* are referenced; values are set with `gcloud secrets versions add`.
- No service-account keys anywhere. CI authenticates with Workload Identity Federation only.
- Least privilege: the deployer gets `artifactregistry.writer` on one repo, `run.developer` on one service, and
  `iam.serviceAccountUser` on that service's runtime account. Nothing project-wide.
- `prod` has `deletion_protection`, regional availability, PITR backups and `min_instances >= 1`; do not weaken.
- Terraform never owns the running image: CI deploys it and `ignore_changes` keeps applies from rolling it back.
- Every module exposes typed variables with descriptions and validated inputs; outputs are the only cross-module API.
- `tofu fmt` is the formatter; the gate fails on unformatted files.
- Never run `apply` from an agent session; agents produce plans, humans apply.

## Skills

| Skill | When |
|-------|------|
| `add-module` | New kind of resource (queue, bucket, scheduler…) as a module with inputs, outputs, a mocked test |
| `add-environment` | New env (staging…) as tfvars + backend + CI environment |
| `brainstorm-spec`, `tdd`, `debug`, `code-review`, `council-review`, `verify-before-done`, `adr`, `git-hygiene` | Kit workflow skills |

## Subagents

`planner`, `tdd-implementer`, `reviewer`, `security-reviewer`, `explorer`, `council-synthesizer` in `.claude/agents/`.

## Definition of done

Spec acceptance criteria met · mocked test covers the change · `just check` green (output pasted) · plan reviewed
for the target env · no placeholders · README/ADR updated · conventional commit.
