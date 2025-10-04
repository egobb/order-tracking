#####################################
# MSK Serverless (usa subnets públicas)

# SG para el cluster (sin ingress aquí; lo abrimos desde env con SG→SG)
resource "aws_security_group" "msk" {
  name        = "ot-msk-sls-sg"
  description = "Security Group for MSK Serverless"
  vpc_id      = local.vpc_id

  # egress abierto; inbound lo controlamos desde env
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Cluster MSK Serverless
resource "aws_msk_serverless_cluster" "this" {
  cluster_name = "ot-msk-sls"

  vpc_config {
    # MSK Serverless exige subnets en al menos 2 AZ
    subnet_ids      = local.public_subnet_ids
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }

}

# Bootstrap brokers (SASL_IAM, puerto 9098)
# Desde AWS Provider v5x ya expone el atributo directamente
output "msk_bootstrap_brokers" {
  value = aws_msk_serverless_cluster.this.bootstrap_brokers_sasl_iam
}

output "msk_sg_id" {
  value = aws_security_group.msk.id
}
