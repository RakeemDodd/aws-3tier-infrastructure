Build Log — AWS 3-Tier Infrastructure (Terraform)

Rebuilding a 3-tier AWS architecture (VPC, EC2, RDS, ALB) using Terraform — hands-on, from the ground up — to fully internalize the architecture and be able to explain and defend every component.

Milestones
Environment Setup
Verified Terraform, AWS CLI, and Git installed and working
Upgraded Terraform to v1.15.8 via official HashiCorp Homebrew tap
Verified AWS CLI authentication (aws sts get-caller-identity)
Initialized Git repository
Created .gitignore (excludes state files, secrets, local Terraform cache)
First commit made
Networking Foundation
Built the VPC (10.0.0.0/16) as the base network container
Created 4 subnets across 2 Availability Zones — public_a, public_b, private_a, private_b
Set map_public_ip_on_launch = true on public subnets, explicitly false on private subnets
Attached an Internet Gateway to the VPC
Built a public route table routing 0.0.0.0/0 to the Internet Gateway, associated with both public subnets
Created two Elastic IPs, one per Availability Zone, for the NAT Gateways
Built two NAT Gateways, one per AZ, each placed in its corresponding public subnet
Built two separate private route tables (one per AZ, each routing to its own NAT Gateway) so each AZ stays independently redundant, then associated each with its matching private subnet
Security Groups
Built a chained access model across three security groups:
ALB security group: allows inbound HTTP from anywhere
EC2 security group: allows inbound HTTP only from the ALB security group
RDS security group: allows inbound MySQL (port 3306) only from the EC2 security group
All three allow full outbound traffic
Database and Compute
Built an RDS subnet group spanning both private subnets
Built an RDS MySQL 8.0 instance (db.t3.micro) using that subnet group and the RDS security group
Enabled Multi-AZ on RDS for automatic failover
Looked up a current Amazon Linux AMI via a data source
Built an EC2 instance (t3.micro) in a private subnet, attached to the EC2 security group
Added a user_data script that installs and starts Apache plus a MySQL-compatible client, and serves a real HTML page — so the instance runs a working web server, not just an idle box
Load Balancer
Built the Application Load Balancer across both public subnets, attached to the ALB security group
Built a target group with a health check, attached the EC2 instance to it
Added a listener on port 80 forwarding traffic to the target group — completing the path from the internet through the ALB to EC2
IAM and Verification Readiness
Built an IAM role trusted by the EC2 service
Attached the AWS-managed AmazonSSMManagedInstanceCore policy to it
Wrapped it in an instance profile attached to the EC2 instance
Enables access via AWS Systems Manager Session Manager (no SSH keys or open ports) so the deployment can be verified end-to-end, not just planned
Outputs
Added Terraform outputs for the ALB DNS name, RDS endpoint, EC2 private IP, VPC ID, subnet IDs, and NAT Gateway public IPs — so key connection details print automatically after apply
Deployment and Verification
Ran terraform apply and brought up all 30 resources on real AWS infrastructure in us-east-1
Verified in the AWS Console that the VPC, subnets, route tables, NAT Gateways, EC2 instance, and RDS instance all matched the plan
Connected to the running EC2 instance through AWS Systems Manager Session Manager — no SSH keys, no open ports
Ran curl localhost on the instance and confirmed Apache was serving the actual HTML page from user_data
Connected from the EC2 instance to the RDS database over the security group chain and got a live MySQL prompt, confirming the EC2 → RDS path actually works
Opened the ALB's public DNS name in a browser from my own laptop and saw the live page — confirming the full path from the internet, through the load balancer, to EC2
Ran terraform destroy afterward to tear everything down and avoid ongoing cost
Concepts Reinforced

.gitignore prevents sensitive/regenerable files (state, credentials, provider cache) from being tracked or pushed to GitHub. Terraform state files can contain sensitive data in plaintext — must never be committed. Homebrew tap system requires explicit trust for third-party formula sources (HashiCorp moved Terraform off default Homebrew formulae). A VPC's CIDR block determines how many subnets it can be divided into; each subnet claims a distinct, non-overlapping slice. Route tables and route table associations are separate resources — the table defines the rule, the association applies it to a subnet. A NAT Gateway physically lives in a public subnet, even though its purpose is to serve private subnets, because it needs its own path to the internet through the Internet Gateway. depends_on forces resource ordering when a real dependency exists but there's no direct attribute reference between two resources. Official Terraform provider docs are the standard reference for resource syntax — Example Usage gives a working pattern, Argument Reference gives the full technical spec of what's required vs. optional. Security groups can reference other security groups as a traffic source, chaining access control between tiers instead of opening ports to raw IP ranges. Sensitive Terraform variables (like a database password) belong in a gitignored terraform.tfvars file, never hardcoded in the .tf files themselves. Data sources look up existing information (like an AMI ID) rather than creating anything, keeping resource definitions current instead of hardcoded to a value that goes stale. An Application Load Balancer's listener and target group are separate concerns — the target group defines where traffic goes and how health is checked, the listener defines what port/protocol the load balancer itself accepts traffic on. An IAM role's assume_role_policy defines who can use the role, which is separate from the actual permissions granted by an attached policy. An IAM instance profile is required to attach a role to an EC2 instance — the role cannot be attached directly.

Passing AWS health checks only proves an instance booted — it says nothing about whether a user_data script actually succeeded. That only shows up in the instance's own boot log, which cloud-init writes automatically and which is the right place to look whenever a startup script might have failed silently. RDS subnet group names, like several other AWS resource names, must start with a letter — a name starting with a number is silently rejected at apply time, not caught by terraform validate. A wildcard AMI filter can match more than the "obvious" image — Amazon Linux 2023 ships both a standard AMI and a "minimal" variant under similar names, and only the standard one comes with the SSM Agent pre-installed. enable_dns_hostnames on a VPC defaults to false in Terraform even though enable_dns_support defaults to true — a real, commonly-hit gap when building a VPC by hand instead of from a module.

Errors & Fixes

Wrote tags { } instead of tags = { } on a resource block. The missing = caused invalid syntax — tags is a key-value assignment, not a nested block. Set map_public_ip_on_launch = true on both private subnets after copy-pasting the public subnet block as a starting template and missing that one value during review. Fixed by changing both to false.

During apply, the RDS subnet group failed with "Invalid subnet group name" — the name started with a number (3tier-db-subnet-group), which AWS silently rejects. Renamed it to start with a letter (app-db-subnet-group) and re-applied.

After the deploy succeeded, EC2 showed "Running" with passing health checks, but AWS Systems Manager couldn't connect to the instance. Checked the instance's boot log and found the user_data script had actually failed — it was trying to install mysql, a package name that doesn't exist on Amazon Linux 2023 (it's mariadb105 there instead), which stopped the script before Apache ever started. Fixed the package name and used terraform apply -replace to rebuild just the EC2 instance.

SSM still wouldn't connect after that fix. Checked the VPC's DNS settings and found enable_dns_hostnames was false — Terraform doesn't turn this on by default, unlike enable_dns_support. Added it explicitly and applied the change, but SSM still wasn't connecting, which meant this hadn't been the actual cause.

Queried AWS Systems Manager directly (aws ssm describe-instance-information) and got an empty list — confirming the SSM Agent had never registered at all, not just a display delay. Checked exactly which AMI Terraform had picked and found it was the "minimal" variant of Amazon Linux 2023, which doesn't ship with the SSM Agent installed. The AMI filter (al2023-ami-*) was broad enough to match it. Tightened the filter to exclude the minimal variant, rebuilt the EC2 instance again, and SSM connected successfully on the first try afterward.

With SSM working, verified the whole stack for real: curl localhost on the instance returned the actual web page, a mysql login from the instance to RDS succeeded, and the ALB's public URL loaded the same page in a browser on my own laptop. All three confirmed the architecture works end-to-end, not just that terraform apply finished without errors.