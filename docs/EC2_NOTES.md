# EC2 Settings: What Each One Does and Why

A review of every setting on the web server in `ec2.tf`, `iam.tf` and `security_groups.tf`, including the defaults the code doesn't set. Gaps found here are fixed in later updates to this project.

## Summary

| # | Setting | Value | Status |
|---|---|---|---|
| 1 | AMI lookup | Newest official Amazon Linux 2023 (standard) | ⚠️ Replacement risk from `most_recent` |
| 2 | Instance type | `t3.micro` | ✅ Right-sized for a demo |
| 3 | Subnet | `private_a` | ⚠️ Single instance, single AZ |
| 4 | Security group | Port 80 from the ALB only; no SSH | ⚠️ Egress fully open |
| 5 | IAM instance profile | SSM role | ✅ No keys on the server |
| 6 | `user_data` | Installs Apache and a MySQL client | ⚠️ Changes don't reach a running server |
| 7 | Tags | `Name` only | ⚠️ `default_tags` planned |
| 8 | Not in code | Disk encryption, IMDSv2, monitoring | ⚠️ Relying on defaults |

## 1. AMI lookup
- **What:** a `data` source finds the newest official Amazon Linux 2023 image. It reads; it creates nothing.
- **Why:** `owners = ["amazon"]` trusts only images published by AWS, so a look-alike community image can't be picked. The name pattern `al2023-ami-2023*-x86_64` matches the standard image and excludes the minimal variant, which has no SSM Agent (the bug documented in [BUILD_LOG.md](../BUILD_LOG.md)). `x86_64` matches the `t3` family.
- **Risk:** `most_recent = true` means every new Amazon Linux release changes the AMI ID, so `terraform plan` wants to replace the instance even when nothing else changed.
- **Next:** pin the AMI and update it on purpose, or ignore AMI changes, decided in the next code update.

## 2. Instance type: `t3.micro`
- **What:** sets the hardware: 2 vCPUs and 1 GB of RAM.
- **Why:** the cheapest size that runs Apache for a demo page. The `t` family is burstable: it earns CPU credits while idle and spends them on spikes.
- **Risk:** `t3` defaults to unlimited mode, which can bill extra if it runs above baseline for long. Not free once the account's free tier ends.
- **Next:** consider capping CPU credits in the next code update. In production, right-size from CloudWatch metrics.

## 3. Subnet: `private_a`
- **What:** places the server in a private subnet with no public IP.
- **Why:** it can't be reached from the internet. Users come in through the Internet Gateway and the ALB; outbound updates go through the NAT gateway, which is outbound only.
- **Risk:** one instance in one AZ is a single point of failure, even though the ALB spans two AZs.
- **Next:** run across both private subnets with autoscaling when the app moves to containers.

## 4. Security group
- **What:** allows port 80 only from the ALB's security group.
- **Why:** referencing a security group instead of IP ranges keeps working when the ALB's addresses change, and only the ALB can reach the server. There's no SSH rule: access is through SSM Session Manager, which needs no open ports or keys, is controlled by IAM, and is logged.
- **Risk:** egress allows all traffic out.
- **Next:** tighten it to HTTPS out and MySQL to the database's security group, or document why it stays, when the CI pipeline adds a security scan.

## 5. IAM instance profile
- **What:** attaches a role with the AWS-managed `AmazonSSMManagedInstanceCore` policy.
- **Why:** the role gives the server AWS permissions through temporary, automatically rotated credentials, so no access keys are stored on it. The security group controls who can reach the server; the role controls what it can do. EC2 can't attach a role directly, so the instance profile is required.
- **Next:** review the managed policy against least privilege during security hardening.

## 6. `user_data`
- **What:** a bootstrap script that installs Apache and the `mariadb105` MySQL client, then writes the web page.
- **Why:** `systemctl start` runs Apache now; `enable` restarts it on every boot, since `user_data` runs only once, on first boot. The MySQL client was used to verify the EC2 → RDS connection.
- **Risk:** editing the script doesn't affect a running server. A fix during the original build needed `terraform apply -replace` to take effect.
- **Next:** consider `user_data_replace_on_change = true` in the next code update.

## 7. Tags
- **What:** `Name = "3tier-ec2"`, the console display name.
- **Why:** tags show what each resource is, who owns it, and what it costs.
- **Next:** `default_tags` (Project, Owner, then Environment) on every resource through the provider, activated as cost allocation tags so costs can be tracked by project.

## 8. Not set in code (relying on defaults)
- **Disk encryption:** the code doesn't encrypt the root disk, and the account's EBS default encryption is off (checked with `aws ec2 get-ebs-encryption-by-default`), so the disk on the deployed instance was unencrypted. **Next:** set `encrypted = true` and turn on account-wide default encryption, then move to a customer-managed KMS key during security hardening.
- **IMDSv2:** was required on the deployed instance, inherited from the Amazon Linux 2023 image rather than enforced in code. IMDSv2 blocks SSRF attacks that steal the instance's role credentials through the metadata service. **Next:** add `metadata_options { http_tokens = "required" }` so it's guaranteed.
- **Monitoring:** basic metrics every 5 minutes, fine for practice runs. **Next:** detailed 1-minute monitoring when alarms are added.
