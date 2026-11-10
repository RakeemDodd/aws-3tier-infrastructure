output "endpoint" {
  description = "Connection endpoint for the database (host:port)"
  value       = aws_db_instance.main.endpoint
}
