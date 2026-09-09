# agentic-infra command surface. `just check` is the quality gate (offline: mocked providers).
set dotenv-load := true

env := env_var_or_default("ENV", "dev")

default:
    @just --list

# Download providers (no backend); CI and `just check` use this
setup:
    tofu init -backend=false -input=false
    cd bootstrap && tofu init -backend=false -input=false

# Init against the real remote state for ENV (needs ADC: gcloud auth application-default login)
init:
    tofu init -reconfigure -backend-config=envs/{{env}}/backend.hcl

plan: init
    tofu plan -var-file=envs/{{env}}/{{env}}.tfvars -out=.tfplan-{{env}}

apply: init
    tofu apply .tfplan-{{env}}

# One-time per project: create the remote-state bucket
bootstrap PROJECT REGION="asia-south1":
    cd bootstrap && tofu init -input=false && tofu apply -var project_id={{PROJECT}} -var region={{REGION}}

dev:
    @echo "Infra has no dev server. Use: just plan / just apply (ENV=dev|prod)"

# Offline contract tests with mocked providers
test *ARGS:
    tofu test {{ARGS}}

lint:
    tofu fmt -recursive -check -diff
    tofu validate
    cd bootstrap && tofu validate

fmt:
    tofu fmt -recursive

fmt-file FILE:
    tofu fmt "{{FILE}}" >/dev/null 2>&1 || true

typecheck:
    tofu validate

check: lint typecheck test
    @echo "check: green"

council BASE="origin/main":
    scripts/council-review.sh {{BASE}}

# Print the two values an app repo needs as GitHub secrets (after apply)
outputs: init
    tofu output
