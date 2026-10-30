# Part A Plan: Team-Grade Infrastructure as Code

## Goal
Part A turns this single-developer project into infrastructure a team could run: shared and locked state, reusable modules, separate dev and prod environments, and automated checks on every change, so changes are safe, repeatable and reviewed, with no surprise outages or bills.

## Starting point
[v1.0-flat](https://github.com/RakeemDodd/aws-3tier-infrastructure/releases/tag/v1.0-flat): the hand-written Stage 1 stack (flat layout, local state), deployed to AWS, verified end to end, then destroyed.

## Decisions and trade-offs

### 1. Merge method
- **Options:** merge commit, squash merge, rebase
- **Chose:** merge commit, enforced in the branch ruleset
- **Why:** keeps every small commit, so the step-by-step build history stays visible
- **Trade-off accepted:** a busier commit history than squashing

### 2. Budgets
- **Options:** console only, import into a bootstrap config, a separate guardrails config
- **Chose:** import the existing budgets into `bootstrap/` with `import` blocks
- **Why:** cost guardrails become code: versioned, reviewed, rebuildable, and never destroyed with the stack
- **Trade-off accepted:** extra code, plus `prevent_destroy` to protect them

### 3. Demo mode
- **Options:** one switch, separate settings, one switch driving named settings
- **Chose:** one `demo_mode` switch driving named settings (one NAT gateway, single-AZ database), default `true`
- **Why:** one flag to flip, readable code, and forgetting it gives the cheaper build
- **Trade-off accepted:** demo mode isn't the real design, so the full design is still tested before Part A closes

### 4. Environments (dev and prod)
- **Options:** workspaces, a folder per environment, one folder with per-environment settings files
- **Chose:** a folder per environment (`envs/dev`, `envs/prod`)
- **Why:** the folder you're in is the environment you change, and each gets its own state and pipeline gate
- **Trade-off accepted:** a small amount of repeated code in each folder

### 5. Database password
- **Options:** RDS-managed password, a Terraform-generated write-only password, a tfvars file
- **Chose:** RDS-managed, stored in Secrets Manager with automatic rotation
- **Why:** the password never appears in code, on a laptop, or in Terraform state
- **Trade-off accepted:** the app reads it from Secrets Manager, and a small monthly cost per secret

### 6. CLI credentials
- **Options:** switch now, switch alongside CI's move to OIDC, after Part A, never
- **Chose:** IAM Identity Center (SSO), right after OIDC
- **Why:** completes "no long-lived credentials": SSO for people, OIDC for pipelines, roles for workloads
- **Trade-off accepted:** one rotated access key stays in use until then

### Standard practices
- **State bucket:** S3 with native locking, versioning, encryption, all public access blocked, HTTPS only, protected from deletion
- **Modules:** one per layer: network, security, compute, database, load balancer
- **CI pipeline:** format, validate and plan on every pull request, a Checkov security scan, OIDC instead of stored keys, approval before prod, and a scheduled drift check

## Order of work
1. ✅ Tag v1.0-flat and publish the release
2. ✅ Create AWS budget alerts
3. Document why each EC2 setting is set the way it is
4. Restructure the troubleshooting log
5. Bootstrap the S3 state bucket and import the budgets
6. Add the demo-mode switch and provider block
7. Apply in demo mode, destroying at the end of every session
8. Move state to the S3 backend with native locking
9. Reorganize the repo layout
10. Refactor into modules with `moved` blocks
11. Run dev and prod from one codebase
12. Add default tags and move the database password out of state
13. Build the GitHub Actions pipeline

## Risks and how they're handled
- **Losing state during the S3 migration:** back up the local state first; the migration passes only if `terraform plan` shows no changes
- **The module refactor deleting resources:** `moved` blocks; the plan must show moves only
- **Changing the wrong environment:** a separate folder and state per environment, plus an approval gate on prod
- **Surprise costs:** demo mode, two budgets, and destroying the stack the same day

## Cost plan
Practice runs use demo mode and are destroyed the same day. Only the state bucket is kept. A $25 monthly budget (alerts at $10, $20 and $25, plus a forecast alert) and a $2 daily budget catch anything left running. Real monthly cost is measured and published in Part C.

## Done when
- `terraform plan` shows no changes after the state migration
- The module refactor shows moves only, with nothing destroyed
- Dev and prod both apply cleanly from one codebase
- The full design (2 NAT gateways, Multi-AZ) is applied and verified at least once
- Prod changes require approval in the pipeline
- The CI badge is green