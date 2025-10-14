# Public URL of the application through the ALB (HTTP).
# Note: this always returns HTTP even if HTTPS is enabled.
# If you enable HTTPS, consider adding a second output with https://
# or dynamically switch based on var.enable_https.
output "app_url" {
  description = "Public URL (HTTP) of the Application Load Balancer"
  value       = "http://${aws_lb.this.dns_name}"
}

# -------------------------------------------------------------------
# - Provides a quick way to grab the app endpoint after `terraform apply`.
# - Simple for dev where only HTTP is active.
# -------------------------------------------------------------------