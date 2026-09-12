Build Log — AWS 3-Tier Infrastructure (Terraform)

Rebuilding a 3-tier AWS architecture (VPC, EC2, RDS, ALB) using Terraform — hands-on, from the ground up — to fully internalize the architecture and be able to explain and defend every component.

Milestones
Environment Setup

Verified Terraform, AWS CLI, and Git installed and working. Upgraded Terraform to v1.15.8 via official HashiCorp Homebrew tap. Verified AWS CLI authentication (aws sts get-caller-identity). Initialized Git repository. Created .gitignore (excludes state files, secrets, local Terraform cache). First commit made.

Networking Foundation

Built the VPC (10.0.0.0/16) as the base network container. Created 4 subnets across 2 Availability Zones — public_a, public_b, private_a, private_b. Set map_public_ip_on_launch = true on public subnets, explicitly false on private subnets. Attached an Internet Gateway to the VPC. Built a public route table routing 0.0.0.0/0 to the Internet Gateway, associated with both public subnets. Created two Elastic IPs, one per Availability Zone, as the fixed public addresses for the NAT Gateways.

Concepts Reinforced

.gitignore prevents sensitive/regenerable files (state, credentials, provider cache) from being tracked or pushed to GitHub. Terraform state files can contain sensitive data in plaintext — must never be committed. Homebrew tap system requires explicit trust for third-party formula sources (HashiCorp moved Terraform off default Homebrew formulae). A VPC's CIDR block determines how many subnets it can be divided into; each subnet claims a distinct, non-overlapping slice. Route tables and route table associations are separate resources — the table defines the rule, the association applies it to a subnet. A NAT Gateway physically lives in a public subnet, even though its purpose is to serve private subnets, because it needs its own path to the internet through the Internet Gateway. depends_on forces resource ordering when a real dependency exists but there's no direct attribute reference between two resources. Official Terraform provider docs are the standard reference for resource syntax — Example Usage gives a working pattern, Argument Reference gives the full technical spec of what's required vs. optional.

Errors & Fixes

Wrote tags { } instead of tags = { } on a resource block. The missing = caused invalid syntax — tags is a key-value assignment, not a nested block. Set map_public_ip_on_launch = true on both private subnets after copy-pasting the public subnet block as a starting template and missing that one value during review. Fixed by changing both to false.