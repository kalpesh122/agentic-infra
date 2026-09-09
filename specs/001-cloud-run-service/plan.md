# Plan: Cloud Run service

Spec: `spec.md`

## Steps

### 1. Project APIs + registry — `modules/project`, `modules/registry` — test: validate
### 2. Database + secret — `modules/database` — test: socket URL assertion
### 3. Service + runtime SA + probes — `modules/service` — test: naming assertions
### 4. GitHub OIDC + least-privilege IAM — `modules/github-oidc` — test: provider-name assertion
### 5. Root composition, envs, bootstrap, deploy workflow — `main.tf`, `envs/`, `bootstrap/`, `.github/workflows/`

## Rollback

`tofu destroy` per environment (prod requires removing deletion protection first, on purpose).

## Out of scope / follow-ups

- Custom domain module; VPC-only database.
