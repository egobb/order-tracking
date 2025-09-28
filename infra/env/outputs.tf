output "app_url" {
  description = "URL pública (HTTP) del ALB"
  value       = "http://${aws_lb.this.dns_name}"
}
