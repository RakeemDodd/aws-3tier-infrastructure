# Build Log — AWS 3-Tier Infrastructure (Terraform)

Rebuilding a 3-tier AWS architecture (VPC, EC2, RDS, ALB) using Terraform — hands-on, from the ground up — to fully internalize the architecture and be able to explain and defend every component.

---

## Milestones

### Environment Setup

Verified Terraform, AWS CLI, and Git installed and working.
Upgraded Terraform to v1.15.8 via official HashiCorp Homebrew tap.
Verified AWS CLI authentication (`aws sts get-caller-identity`).
Initialized Git repository.
Created `.gitignore` (excludes state files, secrets, local Terraform cache).
First commit made.

---

## Concepts Reinforced

`.gitignore` prevents sensitive/regenerable files (state, credentials, provider cache) from being tracked or pushed to GitHub.
Terraform state files can contain sensitive data in plaintext — must never be committed.
Homebrew tap system requires explicit trust for third-party formula sources (HashiCorp moved Terraform off default Homebrew formulae).

---

## Errors & Fixes

*(will track real issues as they come up)*