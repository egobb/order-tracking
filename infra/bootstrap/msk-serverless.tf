# Security group intended to guard MSK Serverless traffic.
# Note: MSK Serverless does not accept a security group on the cluster resource itself.
# The usual pattern is to control traffic from the *client* SGs (ECS tasks, etc.).
# I leave this SG defined so I can reference its ID from environment modules if I later
# introduce SG-to-SG rules via an intermediate construct (but see notes at the end).
resource "aws_security_group" "msk" {
  name        = "ot-msk-sls-sg"
  description = "Security Group for MSK Serverless"
  vpc_id      = local.vpc_id

  # Allow all egress so clients can reach broker endpoints and AWS services as needed.
  # Inbound is intentionally empty here; client-to-broker flows are initiated outbound.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# MSK Serverless cluster using SASL/IAM auth.
# Subnets must span at least two AZs; I pass filtered public subnets here for bootstrap simplicity.
# If I need tighter network posture, I will move to private subnets with NAT.
resource "aws_msk_serverless_cluster" "this" {
  cluster_name = "ot-msk-sls"

  vpc_config {
    subnet_ids = local.public_subnet_ids
    security_group_ids = [aws_security_group.msk.id]
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }
}

# Bootstrap brokers for SASL/IAM (port 9098). Exposed directly by provider v5+.
output "msk_bootstrap_brokers" {
  value = aws_msk_serverless_cluster.this.bootstrap_brokers_sasl_iam
}

# Keep the SG ID available to wire from environment modules if needed (see notes).
output "msk_sg_id" {
  value = aws_security_group.msk.id
}

# The actual subnets used by the cluster (handy for debugging or client routing).
output "msk_client_subnet_ids" {
  value = aws_msk_serverless_cluster.this.vpc_config[0].subnet_ids
}
