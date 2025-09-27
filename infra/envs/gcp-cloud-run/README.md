# Infra – GCP Cloud Run

This is my Terraform setup to deploy **Order Tracking** on **Google Cloud Run**.  
Goal: show a minimal but working infra example that I can grow step by step.

---

## Prerequisites
- Terraform >= 1.6
- `gcloud` CLI installed and authenticated
  ```bash
  gcloud auth application-default login
  ```
- Billing enabled on my GCP project.

---

## How I use this
1. Copy this folder as `infra/envs/gcp-cloud-run/`.
2. Fill `terraform.tfvars` with:
    - `project_id`
    - `region`
    - `image` → (must be pushed to Artifact Registry first).
3. Init Terraform:
   ```bash
   terraform init
   ```
4. Preview plan:
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```
5. Apply:
   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

Terraform will output the Cloud Run URL when it finishes.

---

## Build & push the image (manual for now)
```bash
REGION="europe-west1"
PROJECT="<my-project-id>"
REPO="order-tracking"
IMAGE="order-tracking:0.1.0"

gcloud auth configure-docker ${REGION}-docker.pkg.dev

docker build -t ${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/${IMAGE} .
docker push ${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/${IMAGE}
```

Then I update `terraform.tfvars.image` with that full path.

---

## Profiles
- **MVP**: use `SPRING_PROFILES_ACTIVE=h2` (no Postgres, no Kafka).
- Later: switch to `pg` profile with Cloud SQL.
- Later: explore Kafka vs Pub/Sub for event streaming.

---

## Roadmap for this env
- [x] Cloud Run + Artifact Registry (this MVP).
- [ ] Cloud Build trigger with `cloudbuild.yaml`.
- [ ] Cloud SQL + VPC Connector.
- [ ] Messaging layer (Kafka via Confluent Cloud or GCP Pub/Sub).
- [ ] Monitoring & alerts with Cloud Monitoring.
- [ ] Private ingress (remove public `allUsers`).
