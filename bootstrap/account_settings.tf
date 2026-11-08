# Every new EBS volume in this region is encrypted, even ones created outside this code
resource "aws_ebs_encryption_by_default" "account" {
  enabled = true

  lifecycle {
    prevent_destroy = true
  }
}
