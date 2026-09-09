---
name: add-module
description: Add a new infrastructure module (bucket, queue, scheduler, cache…) with typed inputs, outputs, least-privilege IAM, and an offline mocked test. Use for any new kind of resource.
argument-hint: [module-name]
---

# Add a module

Reference: `modules/registry` (small) and `modules/service` (IAM + dynamic blocks).

1. `modules/<name>/main.tf`: `variable` blocks with `type` and `description` first, then resources, then `output`s. One concern per module.
2. IAM lives next to the resource it protects (`google_*_iam_member`, never `_iam_policy` or project-wide roles). Grant to service accounts, never to users.
3. Labels: accept `labels` and pass them to every labelable resource.
4. Wire it in `main.tf` with `module "<name>"`, pass `depends_on = [module.project]`, expose what apps need in `outputs.tf`.
5. If the service needs it: add an env var or a secret id in `modules/service` inputs and a `secret_env_vars` entry in the env tfvars.
6. Test: add a `run` block in `tests/plan.tftest.hcl` asserting the module's outputs/naming under `command = plan` with mocked providers.
7. `just check`; then `ENV=dev just plan` and record the summary in the PR.
