output "endpoint" {
  description = "Connection endpoint for the database (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret that holds the master password (the address of the secret, not the password)"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
