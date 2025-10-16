# Infrastructure — `order-tracking/infra`

Infrastructure as Code for automating **bootstrap** (one-time, global resources) and **env** (per-environment resources) on AWS with **Terraform**, **ECS Fargate**, **ECR**, **ALB**, **MSK Serverless**, and **RDS PostgreSQL**.

> Goal: a reproducible and cost‑aware pipeline for development/portfolio showcasing, with a clear path to production hardening.

---

## Requirements

- Terraform `>= 1.7.0`
- AWS CLI with SSO configured (suggested profile: `sso-egobb`)
- Admin‑level permissions in the target AWS account

Sign in with SSO:
```bash
aws sso login --profile sso-egobb
```

---

## Repository layout

```
infra/
├─ bootstrap/                    # Run ONCE (or very rarely)
│  ├─ main.tf                    # Remote state (S3+Dynamo), GitHub OIDC, base IAM roles, ECR
│  ├─ msk-serverless.tf          # MSK Serverless cluster (SASL/IAM)
│  ├─ rds.tf                     # RDS PostgreSQL + Secrets Manager secret
│  ├─ variables.tf               # Bootstrap variables
│  └─ (other .tf: IAM, SGs, outputs)
│
└─ env/                          # Per-workspace environment (dev, staging, prod…)
   ├─ main.tf                    # Backend per workspace + shared locals (naming/FQDN)
   ├─ bootstrap_outputs.tf       # data.terraform_remote_state to read bootstrap outputs
   ├─ datasources-network.tf     # locals: VPC + subnets from bootstrap
   ├─ alb.tf                     # ALB, Target Group, HTTP listener (base for HTTPS)
   ├─ networking.tf              # Security groups for ALB and ECS service
   ├─ ecs.tf                     # ECS Cluster, Task Definition, Service
   ├─ sg.tf                      # SG→SG rules: ECS → RDS (5432), ECS → MSK (9098)
   ├─ outputs.tf                 # Useful outputs (ALB DNS, etc.)
   └─ variables.tf               # Environment variables (image, CPU/Mem, domain…)
```

---

## What we provision (and why)

- **Remote Terraform state**: S3 (versioned) + DynamoDB (state locks). Prevents state corruption in concurrent runs.
- **GitHub OIDC**: deploy without long‑lived credentials. Separate trusts for **DEV** (branches/environment) and **PROD** (tags `v*`).
- **Base IAM**:
    - ECS **execution role** for image pulls, logs, drivers.
    - **PassRole** constrained to `ecs-tasks.amazonaws.com`.
    - **Deployer** roles (DEV/PROD) assumable from GitHub Actions.
- **ECR**: repo `order-tracking` with scan‑on‑push.
- **ECS Fargate**: service + task with CloudWatch Logs; secrets from Secrets Manager.
- **ALB**: HTTP by default; optional HTTPS (ACM + Route53).
- **MSK Serverless**: IAM (SASL/IAM) on port 9098.
- **RDS PostgreSQL**: small instance for dev; credentials in Secrets Manager.
- **Budget**: optional monthly cost guardrail.

---

## Working with the stacks

### 1) Bootstrap (run once)

> **Do not destroy bootstrap** to “save costs”. The expensive bits live in **env** (ALB, ECS, RDS, MSK). Bootstrap (S3+Dynamo, OIDC, roles) costs cents and is your scaffolding.

**First‑time setup (if S3/Dynamo don’t exist yet):**
```bash
cd infra/bootstrap

# Init without backend so we can create the backend resources
terraform init -backend=false

# Create only the state bucket and lock table
terraform apply \
  -target=aws_s3_bucket.tf_state \
  -target=aws_dynamodb_table.tf_lock

# Migrate state to the remote backend (S3 + DynamoDB)
terraform init -migrate-state

# Apply the rest of bootstrap
terraform apply
```

**If backend already exists:**
```bash
terraform init -reconfigure
terraform apply
```

> If you created something *manually* (e.g., the lock table), **import** it into state:
> ```bash
> terraform import aws_dynamodb_table.tf_lock egobb-tf-locks
> ```

### 2) Environment (`env/`) per workspace

```bash
cd ../env

# Create or select a workspace (dev, staging, prod…)
terraform workspace new dev    # first time
terraform workspace select dev

# Init (uses the remote backend with workspace_key_prefix)
terraform init

# Plan and apply
terraform plan
terraform apply
```

Get the app URL:
```bash
terraform output app_url
# → http://<alb-dns>
```

---

## Networking model

- **ALB** in public subnets → accepts Internet traffic.
- **ECS** (for dev simplicity) runs in public subnets with `assign_public_ip = true`.  
  *Exit plan*: move to **private** subnets and disable public IPs.
- **RDS** with `publicly_accessible = false` (private IP only) even if in a public subnet; access is controlled via **SG→SG** from ECS.
- **MSK Serverless**: client access from ECS using **IAM** (SASL/IAM) on port 9098. SG→SG rules open that port from the service SG.

> **Dev rationale:** using public subnets streamlines bootstrap (no NAT per AZ), reduces cost, and allows direct local troubleshooting (e.g., `psql`). This is **not** the final production posture.

---

## HTTPS (optional)

When a domain/hosted zone is ready in Route53:
1. Request an ACM certificate (DNS validation).
2. Add a 443 listener and redirect 80 → 443.
3. (Optional) Create Route53 A/AAAA record to `local.fqdn`.

Variables: `enable_https`, `domain_name`, `subdomain`.

---

## Cost control — pause without breaking

- **ECS**: set `desired_count = 0` or destroy the service.
- **ALB**: destroy (it charges hourly).
- **RDS**: short pause → stop DB instance (up to 7 days); long pause → snapshot + destroy.
- **MSK Serverless**: destroy the cluster when not in use.
- **Bootstrap**: **do not destroy** (keep S3+Dynamo, OIDC, roles).

---

## Hardening checklist (towards prod)

- **Network**: move ECS/RDS to **private** subnets; `assign_public_ip = false`; add VPC Endpoints (S3, Secrets, Logs).
- **IAM**: remove wildcards for Kafka; scope to specific **cluster/topic/group** ARNs. Split build vs deploy policies.
- **RDS**: use `manage_master_user_password = true` (RDS‑managed secret), enable backups, `deletion_protection = true`, final snapshot.
- **ECR**: `image_tag_mutability = IMMUTABLE`, lifecycle policies to expire untagged images.
- **ALB**: enable access logs to S3, HTTPS by default, redirect 80→443.
- **SGs**: restrict ECS egress to just what’s needed (RDS 5432, MSK 9098, 443 for external APIs).
- **State safety**: `lifecycle { prevent_destroy = true }` for the state bucket and lock table.

---

## Common issues & fixes

- **`Error acquiring the state lock… ResourceNotFoundException` (DynamoDB)**  
  The lock table does not exist in that region/account. Create/import it and reconfigure the backend:
  ```bash
  aws dynamodb create-table --table-name egobb-tf-locks ...
  terraform init -reconfigure
  ```

- **`ResourceInUseException: Table already exists` when applying**  
  The resource exists but Terraform state doesn’t know it →
  ```bash
  terraform import aws_dynamodb_table.tf_lock egobb-tf-locks
  ```

- **Secrets Manager: “scheduled for deletion”**  
  Restore then import:
  ```bash
  aws secretsmanager restore-secret --secret-id ot/rds/postgres
  terraform import aws_secretsmanager_secret.pg ot/rds/postgres
  ```

- **ALB 502 / failed health checks**  
  Ensure your health check path (`/actuator/health` by default) returns 200, and that the service SG allows inbound from the ALB SG on `var.container_port`.

---

## Conventions

- **Naming**: `order-tracking-<workspace>` for env resources; `ot-*` for bootstrap resources.
- **Tags** (recommended): `Project=order-tracking`, `Env=<workspace>`, `Owner=egobb`.
- **Workspaces**: default to `dev`. Use `staging` / `prod` as needed.

---

## Design note: public subnets in dev

For **bootstrap/dev**, public subnets are a pragmatic choice (with `publicly_accessible=false` for RDS) that allow:
- Direct local connectivity (e.g., `psql`) for quick validation.
- No NAT Gateways per AZ (lower cost, fewer moving parts).
- Faster initial delivery and troubleshooting.

**Plan:** migrate to **private** subnets once names and resources stabilize, and tighten IAM/SGs accordingly.
