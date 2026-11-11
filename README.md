# AWS 3-Tier Infrastructure (Terraform)

A 3-tier AWS architecture — VPC, EC2, RDS, and an Application Load Balancer — built from scratch in Terraform, deployed to real AWS infrastructure, and verified end-to-end.

This is a rebuild of an [earlier version](https://github.com/RakeemDodd/Terraform-3tier-AWS) of this project, done independently using the official Terraform provider docs as the primary reference, with the goal of fully understanding and being able to defend every component rather than copying a pattern.

> **Status:** Part A (team-grade infrastructure as code) is in progress: remote state, modules, dev and prod environments, and a CI/CD pipeline. The original Stage 1 version is preserved as the [v1.0-flat release](https://github.com/RakeemDodd/aws-3tier-infrastructure/releases/tag/v1.0-flat). Plan and decisions: [docs/PART_A_PLAN.md](docs/PART_A_PLAN.md).

**[Read the full build log →](./BUILD_LOG.md)** — every milestone, plus the real bugs hit and fixed along the way.

![3-tier AWS architecture diagram](./docs/architecture-diagram.jpeg)

## Contents

- [Architecture](#architecture)
- [Verification](#verification)
- [Project Status](#project-status)
- [Terraform Outputs](#terraform-outputs)
- [Project File Structure](#project-file-structure)
- [Tech Stack](#tech-stack)
- [Known Limitations / Next Steps](#known-limitations--next-steps)
- [Running This Yourself](#running-this-yourself)

---

## Architecture

- **VPC** (`10.0.0.0/16`) spanning 2 Availability Zones
- **4 subnets** — 2 public, 2 private, one pair per AZ
- **Internet Gateway** for public subnet traffic
- **2 NAT Gateways** (one per AZ) so private subnets can reach the internet without being reachable from it
- **Application Load Balancer** across both public subnets, routing to EC2
- **EC2 instance** in a private subnet, running Apache, provisioned entirely via Terraform `user_data`
- **RDS MySQL 8.0** with **Multi-AZ** enabled, in the private subnets
- **Security groups chained by tier** — ALB → EC2 → RDS, no open database or app-server ports
- **IAM role + instance profile** giving the EC2 instance AWS Systems Manager access, so it can be verified without SSH keys or open ports

---

## Verification

Every layer of this was actually tested against the live, deployed infrastructure — not just planned and assumed to work.

**Connected to the EC2 instance via AWS Systems Manager Session Manager and confirmed the web server and database were both live:**

![SSM session showing curl and MySQL connection](./docs/screenshots/01-ssm-session-verification.png)

**Confirmed the instance was healthy in the AWS Console:**

![EC2 instance running](./docs/screenshots/02-ec2-instance-running.png)

**Confirmed RDS was available with Multi-AZ enabled:**

![RDS instance available](./docs/screenshots/03-rds-available-multiaz.png)

**Loaded the site through the public Application Load Balancer URL, from outside AWS entirely:**

![Live webpage through the ALB](./docs/screenshots/04-alb-webpage-live.png)

The real bugs hit and fixed during verification — an AMI variant without the SSM Agent, an AWS naming restriction, a wrong package name — are documented in full in [`BUILD_LOG.md`](./BUILD_LOG.md).

---

## Project Status

- ✅ Infrastructure deployed successfully via Terraform, no manual console steps
- ✅ Hand-written resources throughout, organized into my own modules with no third-party code — every line is one I can explain
- ✅ EC2 ↔ RDS connection verified with a live `mysql` login, not just a security group review
- ✅ ALB verified by loading the live page from an external browser
- ✅ EC2 access verified via AWS Systems Manager — no SSH keys, no open ports
- ✅ Full teardown verified — `terraform destroy` confirmed and cross-checked in the AWS Console
- ⚙️ Not yet built: HTTPS, Secrets Manager integration, CloudWatch alarms (see [Known Limitations](#known-limitations--next-steps))

---

## Terraform Outputs

| Output | Description |
|---|---|
| `vpc_id` | ID of the created VPC |
| `public_subnet_ids` | IDs of the two public subnets |
| `private_subnet_ids` | IDs of the two private subnets |
| `ec2_private_ip` | Private IP of the EC2 instance |
| `rds_endpoint` | RDS connection endpoint (host:port) |
| `alb_dns_name` | Public DNS name of the load balancer — this is the URL to visit |
| `nat_gateway_ips` | Public IPs of the NAT gateways (one in demo mode, two in the full design) |

---

## Project File Structure

```
aws-3tier-infrastructure/
├── bootstrap/          State bucket, budgets and account settings (applied once, kept)
├── modules/            Reusable building blocks, one per layer
│   ├── network/
│   ├── security/
│   ├── compute/
│   ├── database/
│   └── load_balancer/
├── envs/
│   ├── dev/            The dev environment: calls the modules with dev settings (demo mode)
│   └── prod/           The prod environment: the same modules with prod settings (full design)
├── scripts/            Helper scripts
└── docs/               Plan, notes, diagram and screenshots
```

### `bootstrap/`

| File | Description |
|---|---|
| `versions.tf` | Version constraints, AWS provider with default tags, and the S3 backend for bootstrap's own state |
| `state_bucket.tf` | S3 state bucket: versioned, encrypted, public access blocked, HTTPS only, protected from deletion |
| `budgets.tf` | Monthly and daily AWS budgets with email alerts, imported into Terraform |
| `account_settings.tf` | EBS encryption on by default for the account |
| `variables.tf` | Alert email input (the value lives in a git-ignored `terraform.tfvars`) |

### `modules/`

Each module has its resources plus `variables.tf` (inputs), `outputs.tf` (what other modules can use) and `versions.tf` (provider requirements only; the provider itself comes from the environment). Every resource is named `<environment>-3tier-<resource>`, for example `prod-3tier-alb`.

| Module | Resources | Inputs |
|---|---|---|
| `network` | VPC, 4 subnets across 2 AZs, Internet Gateway, NAT gateways and Elastic IPs (one in demo mode, two in the full design), route tables and associations | Name prefix, VPC address range, second NAT gateway on or off |
| `security` | Security groups chained by tier: ALB to EC2 to RDS | Name prefix, VPC |
| `compute` | EC2 instance (AMI lookup, IMDSv2, encrypted root volume, `user_data` bootstrap script) and its IAM role and instance profile for SSM | Name prefix, private subnet, security group |
| `database` | RDS MySQL instance and subnet group (single-AZ in demo mode, Multi-AZ in the full design) | Name prefix, private subnets, security group, password, Multi-AZ on or off |
| `load_balancer` | Application Load Balancer, target group and attachment, listener | Name prefix, VPC, public subnets, security group, instance |

### `envs/dev/` and `envs/prod/`

Both environments use the same files, so a change to the modules reaches both. Each has its own state, so applying one never touches the other.

| File | Description |
|---|---|
| `main.tf` | Calls the five modules and wires each module's outputs into the next one's inputs (identical in both) |
| `locals.tf` | The environment's name, name prefix and VPC range (dev `10.0.0.0/16`, prod `10.1.0.0/16`), plus the settings derived from demo mode |
| `variables.tf` | Inputs: database password, region, and the demo mode switch (on by default in dev, off in prod) |
| `versions.tf` | Version constraints, AWS provider with default tags, and the S3 backend with native locking, with a separate state key per environment |
| `outputs.tf` | Terraform outputs, passed through from the modules |
| `moved.tf` | Dev only: records where each resource moved when the code was split into modules, so Terraform renamed them in state instead of replacing them |
| `.terraform.lock.hcl` | Locked provider versions, the same in both environments |
| `terraform.tfvars` | Database password, separate per environment, git-ignored and never committed |

### Other files

| File | Description |
|---|---|
| `scripts/leftover-check.sh` | Confirms nothing billable is still running after a destroy |
| `.gitignore` | Excludes state, plan and `.tfvars` files, and other sensitive or generated files |
| `BUILD_LOG.md` | Full milestone and debugging log |
| `docs/PART_A_PLAN.md` | Part A plan: decisions and trade-offs |
| `docs/EC2_NOTES.md` | Why each EC2 setting is set the way it is, and the gaps to close |

---

## Tech Stack

- Terraform (`~> 6.0` AWS provider)
- AWS: VPC, EC2, RDS, ALB, NAT Gateway, IAM, Systems Manager
- Amazon Linux 2023

---

## Known Limitations / Next Steps

This build is scoped as a demo/learning project and intentionally leaves out a few things that would matter in a persistent production environment:

- **No HTTPS** — the ALB listener is HTTP-only. Adding this would require a registered domain and an ACM certificate, which didn't fit a short-lived demo.
- **No Secrets Manager** — the database password is passed via a git-ignored `terraform.tfvars` file rather than AWS Secrets Manager. Fine for a single-developer demo; a team environment would use Secrets Manager for rotation and access control.
- **No CloudWatch alarms/monitoring** — this infrastructure exists for a few minutes at a time for testing, not as an always-on service, so there was nothing meaningful to alert on.

---

## Running This Yourself

The state bucket name in the backend blocks is globally unique to this account, so change it in `bootstrap/versions.tf`, `envs/dev/versions.tf` and `envs/prod/versions.tf` first.

**1. Bootstrap (once, from the repo root).** Creates the state bucket, budgets and account settings. On the very first run the bucket doesn't exist yet, so comment out the `backend "s3"` block, apply with local state, then restore the block and move the state into the bucket:

```bash
cd bootstrap
terraform init
terraform apply
terraform init -migrate-state
```

**2. An environment (from the repo root).** Add a `terraform.tfvars` with `db_password` (see `variables.tf`) in the environment's folder. Dev runs in demo mode by default (one NAT gateway, single-AZ database) to keep practice runs cheap; prod runs the full design (two NAT gateways, Multi-AZ database).

```bash
cd envs/dev    # or envs/prod
terraform init
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
```

**3. Clean up the same day.** This creates real, billable AWS resources (mainly the NAT gateway, the ALB and RDS). Destroy the stack, then confirm nothing is left running:

```bash
terraform destroy
../../scripts/leftover-check.sh
```

---

## Author

**Rakeem Dodd**
[GitHub Profile](https://github.com/RakeemDodd)
