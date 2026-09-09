@AGENTS.md

## Claude Code specifics

- Use the `add-module` and `add-environment` skills.
- Hooks enforce the hard rules in AGENTS.md (dangerous commands, `.env`, lockfiles, `tofu fmt` on edit, `just check` on stop). Do not work around them.
- You may run `just plan`; never `just apply` or `tofu destroy`. Paste plan summaries; a human applies.
- Provider docs: registry.terraform.io/providers/hashicorp/google/latest/docs (resource names are `google_*`, Cloud Run is the `_v2` family).
