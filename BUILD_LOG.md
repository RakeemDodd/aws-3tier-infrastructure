# Build Log — AWS 3-Tier Infrastructure (Terraform)

Rebuilding a 3-tier AWS architecture (VPC, EC2, RDS, ALB) using Terraform — hands-on, from the ground up — to fully internalize the architecture and be able to explain and defend every component.

## Milestones

### Environment Setup

- Verified Terraform, AWS CLI, and Git installed and working
- Upgraded Terraform to v1.15.8 via official HashiCorp Homebrew tap
- Verified AWS CLI authentication (aws sts get-caller-identity)
- Initialized Git repository
- Created .gitignore (excludes state files, secrets, local Terraform cache)
- First commit made

### Networking Foundation

- Built the VPC (10.0.0.0/16) as the base network container
- Created 4 subnets across 2 Availability Zones — public_a, public_b, private_a, private_b
- Set map_public_ip_on_launch = true on public subnets, explicitly false on private subnets
- Attached an Internet Gateway to the VPC
- Built a public route table routing 0.0.0.0/0 to the Internet Gateway, associated with both public subnets
- Created two Elastic IPs, one per Availability Zone, for the NAT Gateways
- Built two NAT Gateways, one per AZ, each placed in its corresponding public subnet
- Built two separate private route tables (one per AZ, each routing to its own NAT Gateway) so each AZ stays independently redundant, then associated each with its matching private subnet

### Security Groups

- Built a chained access model across three security groups:
  - ALB security group: allows inbound HTTP from anywhere
  - EC2 security group: allows inbound HTTP only from the ALB security group
  - RDS security group: allows inbound MySQL (port 3306) only from the EC2 security group
  - All three allow full outbound traffic

### Database and Compute

- Built an RDS subnet group spanning both private subnets
- Built an RDS MySQL 8.0 instance (db.t3.micro) using that subnet group and the RDS security group
- Enabled Multi-AZ on RDS for automatic failover
- Looked up a current Amazon Linux AMI via a data source
- Built an EC2 instance (t3.micro) in a private subnet, attached to the EC2 security group
- Added a user_data script that installs and starts Apache plus a MySQL-compatible client, and serves a real HTML page — so the instance runs a working web server, not just an idle box

### Load Balancer

- Built the Application Load Balancer across both public subnets, attached to the ALB security group
- Built a target group with a health check, attached the EC2 instance to it
- Added a listener on port 80 forwarding traffic to the target group — completing the path from the internet through the ALB to EC2

### IAM and Verification Readiness

- Built an IAM role trusted by the EC2 service
- Attached the AWS-managed AmazonSSMManagedInstanceCore policy to it
- Wrapped it in an instance profile attached to the EC2 instance
- Enables access via AWS Systems Manager Session Manager (no SSH keys or open ports) so the deployment can be verified end-to-end, not just planned

### Outputs

- Added Terraform outputs for the ALB DNS name, RDS endpoint, EC2 private IP, VPC ID, subnet IDs, and NAT Gateway public IPs — so key connection details print automatically after apply

### Deployment and Verification

- Ran terraform apply and brought up all 30 resources on real AWS infrastructure in us-east-1
- Verified in the AWS Console that the VPC, subnets, route tables, NAT Gateways, EC2 instance, and RDS instance all matched the plan
- Connected to the running EC2 instance through AWS Systems Manager Session Manager — no SSH keys, no open ports
- Ran curl localhost on the instance and confirmed Apache was serving the actual HTML page from user_data
- Connected from the EC2 instance to the RDS database over the security group chain and got a live MySQL prompt, confirming the EC2 → RDS path actually works
- Opened the ALB's public DNS name in a browser from my own laptop and saw the live page — confirming the full path from the internet, through the load balancer, to EC2
- Ran terraform destroy afterward to tear everything down and avoid ongoing cost

## Concepts Reinforced

- .gitignore prevents sensitive/regenerable files (state, credentials, provider cache) from being tracked or pushed to GitHub.
- Terraform state files can contain sensitive data in plaintext — must never be committed.
- Homebrew tap system requires explicit trust for third-party formula sources (HashiCorp moved Terraform off default Homebrew formulae).
- A VPC's CIDR block determines how many subnets it can be divided into; each subnet claims a distinct, non-overlapping slice.
- Route tables and route table associations are separate resources — the table defines the rule, the association applies it to a subnet.
- A NAT Gateway physically lives in a public subnet, even though its purpose is to serve private subnets, because it needs its own path to the internet through the Internet Gateway.
- depends_on forces resource ordering when a real dependency exists but there's no direct attribute reference between two resources.
- Official Terraform provider docs are the standard reference for resource syntax — Example Usage gives a working pattern, Argument Reference gives the full technical spec of what's required vs. optional.
- Security groups can reference other security groups as a traffic source, chaining access control between tiers instead of opening ports to raw IP ranges.
- Sensitive Terraform variables (like a database password) belong in a gitignored terraform.tfvars file, never hardcoded in the .tf files themselves.
- Data sources look up existing information (like an AMI ID) rather than creating anything, keeping resource definitions current instead of hardcoded to a value that goes stale.
- An Application Load Balancer's listener and target group are separate concerns — the target group defines where traffic goes and how health is checked, the listener defines what port/protocol the load balancer itself accepts traffic on.
- An IAM role's assume_role_policy defines who can use the role, which is separate from the actual permissions granted by an attached policy.
- An IAM instance profile is required to attach a role to an EC2 instance — the role cannot be attached directly.
- Passing AWS health checks only proves an instance booted — it says nothing about whether a user_data script actually succeeded. That only shows up in the instance's own boot log, which cloud-init writes automatically and which is the right place to look whenever a startup script might have failed silently.
- RDS subnet group names, like several other AWS resource names, must start with a letter — a name starting with a number is silently rejected at apply time, not caught by terraform validate.
- A wildcard AMI filter can match more than the "obvious" image — Amazon Linux 2023 ships both a standard AMI and a "minimal" variant under similar names, and only the standard one comes with the SSM Agent pre-installed.
- enable_dns_hostnames on a VPC defaults to false in Terraform even though enable_dns_support defaults to true — a real, commonly-hit gap when building a VPC by hand instead of from a module.

## Errors & Fixes

- Wrote tags { } instead of tags = { } on a resource block. The missing = caused invalid syntax — tags is a key-value assignment, not a nested block.
- Set map_public_ip_on_launch = true on both private subnets after copy-pasting the public subnet block as a starting template and missing that one value during review. Fixed by changing both to false.
- During apply, the RDS subnet group failed with "Invalid subnet group name" — the name started with a number (3tier-db-subnet-group), which AWS silently rejects. Renamed it to start with a letter (app-db-subnet-group) and re-applied.
- After the deploy succeeded, EC2 showed "Running" with passing health checks, but AWS Systems Manager couldn't connect to the instance. Checked the instance's boot log and found the user_data script had actually failed — it was trying to install mysql, a package name that doesn't exist on Amazon Linux 2023 (it's mariadb105 there instead), which stopped the script before Apache ever started. Fixed the package name and used terraform apply -replace to rebuild just the EC2 instance.
- SSM still wouldn't connect after that fix. Checked the VPC's DNS settings and found enable_dns_hostnames was false — Terraform doesn't turn this on by default, unlike enable_dns_support. Added it explicitly and applied the change, but SSM still wasn't connecting, which meant this hadn't been the actual cause.
- Queried AWS Systems Manager directly (aws ssm describe-instance-information) and got an empty list — confirming the SSM Agent had never registered at all, not just a display delay. Checked exactly which AMI Terraform had picked and found it was the "minimal" variant of Amazon Linux 2023, which doesn't ship with the SSM Agent installed. The AMI filter (al2023-ami-*) was broad enough to match it. Tightened the filter to exclude the minimal variant, rebuilt the EC2 instance again, and SSM connected successfully on the first try afterward.
- With SSM working, verified the whole stack for real: curl localhost on the instance returned the actual web page, a mysql login from the instance to RDS succeeded, and the ALB's public URL loaded the same page in a browser on my own laptop. All three confirmed the architecture works end-to-end, not just that terraform apply finished without errors.


---

## Part A: Team-Grade Infrastructure as Code

Plan, decisions and trade-offs: [docs/PART_A_PLAN.md](docs/PART_A_PLAN.md). The Stage 1 version above is preserved as the [v1.0-flat release](https://github.com/RakeemDodd/aws-3tier-infrastructure/releases/tag/v1.0-flat).

### Milestones

#### Starting point and safeguards

- Verified the starting state: repo in sync with GitHub, configuration valid, and no leftover AWS resources (NAT Gateways, Elastic IPs, load balancers, databases or instances)
- Upgraded Terraform from 1.15.8 to 1.17.1 and confirmed the configuration still validates
- Confirmed MFA on the root user and the IAM admin user, with no root access keys
- Rotated the CLI access key (462 days old): created a new key, switched the CLI to it, verified it, then deactivated the old key
- Replaced the old budget with two account-wide budgets: a $25 monthly cap (alerts at $10, $20 and $25, plus a forecast alert) and a $2 daily tripwire for anything left running
- Switched Git to GitHub's private noreply email for all new commits and tags
- Turned on push protection, secret scanning, Dependabot alerts and malware alerts for the repository
- Protected main with a branch ruleset: pull requests required, force pushes and deletion blocked, merge commits only
- Tagged the Stage 1 repo as v1.0-flat and published it as a GitHub release, a permanent "before" snapshot
- Wrote the Part A plan: the options, trade-offs and choice for each major decision
- Reviewed every EC2 setting, including the defaults the code doesn't set, and found the gaps to fix: an unencrypted root disk (account default encryption is off), IMDSv2 inherited from the image rather than enforced in code, AMI updates forcing instance replacement, and fully open egress ([docs/EC2_NOTES.md](docs/EC2_NOTES.md))
- Built a separate bootstrap setup for Terraform's remote state: an S3 bucket that's versioned, encrypted, blocks all public access, only accepts HTTPS, expires old state versions after 90 days, and can't be destroyed by Terraform. Its own state lives in the same bucket
- Brought the two console-created budgets under Terraform with import blocks, protected both from deletion, and kept the alert email out of the repo
- Pinned the region, the Terraform version range and default tags (Project, Owner, ManagedBy) in a provider block, so the stack no longer depends on local CLI settings
- Added a demo mode switch: practice builds use one NAT gateway and a single-AZ database while the network still spans two Availability Zones. Plans confirmed 28 resources in demo mode and 30 in the full design
- Hardened the EC2 instance (IMDSv2 required, encrypted root disk, standard CPU credits, startup-script changes rebuild the instance, new Amazon Linux releases no longer force a replacement) and turned on EBS encryption by default for the account
- Ran the first deploy in demo mode from a saved plan (28 resources), confirmed no drift right after the apply, and verified on the live resources: the web page loaded through the load balancer, IMDSv2 was required, the root disk was encrypted, CPU credits were standard and the database was single-AZ. Destroyed it the same session with a clean leftover check (about 25 minutes, roughly $0.05)
- Added Terraform plan files to `.gitignore`, since a saved plan can contain sensitive values
- Moved the app's Terraform state from my laptop into the S3 backend with native locking: deployed in demo mode, backed up the local state, ran `terraform init -migrate-state`, then confirmed the same 29 state entries and a no-changes plan reading from S3. Destroyed the stack through the S3 backend afterwards, with a clean leftover check
- Reorganized the repo for multiple environments: moved the stack into `envs/dev/` with `git mv` so every file keeps its history, kept the same state key so no migration was needed, and confirmed the plan was unchanged (28 to add) from the new folder. Added `scripts/leftover-check.sh`, which checks for NAT gateways, Elastic IPs, load balancers, databases and instances after every destroy and fails if anything is left
- Split the dev stack into five modules (network, security, compute, database and load balancer) that the dev environment calls, and recorded every address change in `moved` blocks. Proved it on a live deployment: the refactor's plan showed 28 moves with nothing added, changed or destroyed, the site kept serving through the change, and the stack was destroyed the same session
- Ran dev and prod from the same modules: every resource is named `<environment>-3tier-<resource>`, each environment has its own VPC range (`10.0.0.0/16` and `10.1.0.0/16`) and its own state, and prod defaults to the full design. Deployed both side by side (58 resources), confirmed each environment's plan showed no changes and only saw its own stack, verified prod's two NAT gateways and Multi-AZ database, loaded both sites, and destroyed both the same session

### Troubleshooting

#### Terraform wouldn't upgrade past 1.15.8

- **Symptom:** `brew upgrade hashicorp/tap/terraform` reported 1.15.8 as already installed, even though `terraform version` said 1.17.1 was available
- **How I found it:** compared the newest commit in my local copy of HashiCorp's Homebrew tap (April 2025) with the tap on GitHub (October 2026), then checked which branch the local copy was tracking: `master`
- **Cause:** HashiCorp had renamed the tap's default branch from `master` to `main`. My local copy kept tracking the old branch, so `brew update` silently stopped refreshing it
- **Fix:** removed and re-added the tap so it tracks `main`, then installed 1.17.1 and re-ran `terraform validate`
- **Lesson:** removing the tap with `--force` also uninstalled Terraform, which I hadn't expected. Check what a fix does before running it, not just whether it works

#### Budget alert emails stuck at "0/1 verified"

- **Symptom:** after creating the budget, its email recipient stayed unverified, a manual resend reported "Failed to send verification," and the link in the email said the token didn't match
- **How I found it:** AWS's docs showed that saving a budget sends a verification email automatically and that resends have a cooldown. The emails were landing in my spam folder, and CloudTrail showed each resend issuing a new activation code
- **Cause:** each verification request replaces the previous code, so the email I opened carried a code that was no longer valid
- **Fix:** resent once, opened only the newest email, confirmed the sender and link were genuine, and verified. The second budget was verified automatically, since verification is per account, not per budget
- **Lesson:** trigger it once, wait, check spam, and use only the newest email. An alert that can't reach you isn't a guardrail

#### Generated import code failed validation

- **Symptom:** `terraform plan -generate-config-out` wrote the budget resources, but the plan failed with "all of `filter_expression,metrics` must be specified"
- **How I found it:** read the generated file line by line and compared it with the budgets in the console. It included a `metrics` setting that AWS fills in by default, without the setting the provider requires alongside it
- **Cause:** the generator copies every value AWS returns, including defaults the provider only accepts together with other settings. Terraform documents the feature as experimental
- **Fix:** removed `metrics` and the other empty defaults, added `ignore_changes = [metrics]` so Terraform leaves AWS's default alone, and applied only once the plan showed nothing but tag changes
- **Lesson:** generated code is a first draft. Review it line by line, and only apply an import when the plan shows exactly the changes you intended

#### Module refactor planned to replace the whole stack

- **Symptom:** with the resources moved into modules, `terraform plan` against the live stack showed 28 to add and 28 to destroy, including `aws_db_instance.main will be destroyed (because aws_db_instance.main is not in configuration)`
- **How I found it:** ran the plan against the live stack before adding any `moved` blocks, to see exactly what Terraform would do, then filtered it for the database to read the reason it gave
- **Cause:** Terraform tracks each resource by its address in the code. Moving the database into a module changed its address from `aws_db_instance.main` to `module.database.aws_db_instance.main`, so Terraform saw one resource removed and another added, even though the settings were identical
- **Fix:** added `moved` blocks mapping every old address to its new one. The plan dropped to 0 to add, 0 to change and 0 to destroy with 28 moves, and the apply only renamed entries in state
- **Lesson:** a refactor that changes addresses is a destroy and recreate unless state is told otherwise. Read every plan for unexpected destroys, and keep the `moved` blocks in the code so any older state can still migrate
