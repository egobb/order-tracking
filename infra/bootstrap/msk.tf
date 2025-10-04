#####################################
# Networking discovery (privadas)
#####################################

data "aws_vpc" "this" {
  default = true
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
}

locals {
  private_subnet_ids = data.aws_subnets.private.ids
}

#####################################
# Security Group for MSK
#####################################

resource "aws_security_group" "msk" {
  name   = "ot-msk-sg"
  vpc_id = data.aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#####################################
# MSK Cluster
#####################################

resource "aws_msk_cluster" "this" {
  cluster_name           = "ot-msk"
  kafka_version          = "3.7.0"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    client_subnets  = local.private_subnet_ids
    security_groups = [aws_security_group.msk.id]
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
      in_cluster    = true
    }
  }
}

#####################################
# Outputs
#####################################

output "msk_bootstrap_brokers" {
  value = aws_msk_cluster.this.bootstrap_brokers
}

output "msk_sg_id" {
  value = aws_security_group.msk.id
}
