#!/usr/bin/env bash
#
# leftover-check.sh
# Run after `terraform destroy` to confirm nothing billable is still running.
# Every check should print []. Exits with code 1 if anything is found.
#
# Usage: scripts/leftover-check.sh             (defaults to us-east-1)
#        AWS_REGION=us-west-2 scripts/leftover-check.sh

set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
found=0

check() {
  local label="$1"
  shift
  local result
  result="$("$@" --region "$REGION" --output json)"
  printf '%-16s %s\n' "$label" "$result"
  if [ "$result" != "[]" ]; then
    found=1
  fi
}

echo "Leftover check in $REGION"

check "NAT gateways" aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=pending,available,deleting" \
  --query "NatGateways[].NatGatewayId"

check "Elastic IPs" aws ec2 describe-addresses \
  --query "Addresses[].AllocationId"

check "Load balancers" aws elbv2 describe-load-balancers \
  --query "LoadBalancers[].LoadBalancerName"

check "RDS instances" aws rds describe-db-instances \
  --query "DBInstances[].DBInstanceIdentifier"

check "EC2 instances" aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=pending,running,shutting-down,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId"

if [ "$found" -eq 0 ]; then
  echo "PASS: nothing billable left running."
else
  echo "FAIL: resources still exist. Check the lines above."
  exit 1
fi
