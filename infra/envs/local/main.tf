terraform {
  required_version = ">= 1.8.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Provider uses DOCKER_HOST=ssh://user@host (set in GitHub Actions)
provider "docker" {}

locals {
  app_image     = var.app_image
  domain        = var.domain
  email         = var.letsencrypt_email
  db_user       = "app"
  db_name       = "ordertracking"
  db_password   = var.db_password
  kafka_image   = "redpandadata/redpanda:v24.1.3"
  traefik_image = "traefik:v3.1"
}

# Networks
resource "docker_network" "proxy"   { name = "proxy" }
resource "docker_network" "backend" { name = "backend" }

# Volumes
resource "docker_volume" "pgdata"           { name = "pgdata" }
resource "docker_volume" "redpanda_data"    { name = "redpanda_data" }
resource "docker_volume" "traefik_acme"     { name = "traefik_acme" }

# Traefik (reverse proxy + TLS)
resource "docker_container" "traefik" {
  name    = "traefik"
  image   = local.traefik_image
  restart = "unless-stopped"

  networks_advanced { name = docker_network.proxy.name }

  ports {
    internal = 80
    external = 80
    protocol = "tcp"
  }

  ports {
    internal = 443
    external = 443
    protocol = "tcp"
  }

  volumes {
    container_path = "/var/run/docker.sock"
    host_path      = "/var/run/docker.sock"
    read_only      = true
  }
  volumes {
    container_path = "/letsencrypt"
    volume_name    = docker_volume.traefik_acme.name
    read_only      = false
  }

  env = [ "TZ=Europe/Madrid" ]

  command = [
    "--entrypoints.web.address=:80",
    "--entrypoints.websecure.address=:443",

    "--providers.docker=true",
    "--providers.docker.exposedbydefault=false",

    "--entrypoints.web.http.redirections.entrypoint.to=websecure",
    "--entrypoints.web.http.redirections.entrypoint.scheme=https",

    "--certificatesresolvers.le.acme.tlschallenge=true",
    "--certificatesresolvers.le.acme.email=${local.email}",
    "--certificatesresolvers.le.acme.storage=/letsencrypt/acme.json"
  ]
}

# PostgreSQL (internal only)
resource "docker_container" "db" {
  name    = "postgres"
  image   = "postgres:16"
  restart = "unless-stopped"

  networks_advanced { name = docker_network.backend.name }

  env = [
    "POSTGRES_DB=${local.db_name}",
    "POSTGRES_USER=${local.db_user}",
    "POSTGRES_PASSWORD=${local.db_password}",
    "TZ=Europe/Madrid"
  ]

  volumes {
    volume_name    = docker_volume.pgdata.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${local.db_user} -d ${local.db_name}"]
    interval = "10s"
    timeout  = "3s"
    retries  = 10
  }
}

# Redpanda (single-node Kafka, internal only)
resource "docker_container" "kafka" {
  name    = "redpanda"
  image   = local.kafka_image
  restart = "unless-stopped"

  networks_advanced { name = docker_network.backend.name }

  command = [
    "redpanda", "start",
    "--mode", "dev-container",
    "--overprovisioned",
    "--smp", "1",
    "--memory", "1024M",
    "--kafka-addr", "internal://0.0.0.0:9092",
    "--advertise-kafka-addr", "internal://kafka:9092"
  ]

  volumes {
    volume_name    = docker_volume.redpanda_data.name
    container_path = "/var/lib/redpanda/data"
  }

  healthcheck {
    test     = ["CMD-SHELL", "rpk cluster info || exit 1"]
    interval = "15s"
    timeout  = "5s"
    retries  = 20
  }
}

# Order Tracking App
resource "docker_container" "app" {
  name    = "order-tracking"
  image   = local.app_image
  restart = "unless-stopped"

  depends_on = [
    docker_container.db,
    docker_container.kafka,
    docker_container.traefik
  ]

  networks_advanced { name = docker_network.backend.name }
  networks_advanced { name = docker_network.proxy.name }

  env = [
    "SPRING_PROFILES_ACTIVE=pg",
    "SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/${local.db_name}",
    "SPRING_DATASOURCE_USERNAME=${local.db_user}",
    "SPRING_DATASOURCE_PASSWORD=${local.db_password}",
    "SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092",
    "TZ=Europe/Madrid"
  ]

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.ordertracking.rule"
    value = "Host(`${local.domain}`)"
  }

  labels {
    label = "traefik.http.routers.ordertracking.entrypoints"
    value = "websecure"
  }

  labels {
    label = "traefik.http.routers.ordertracking.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.ordertracking.tls.certresolver"
    value = "le"
  }

  labels {
    label = "traefik.http.services.ordertracking.loadbalancer.server.port"
    value = "8080"
  }

  healthcheck {
    test     = ["CMD", "wget", "-qO-", "http://localhost:8080/actuator/health"]
    interval = "15s"
    timeout  = "3s"
    retries  = 20
  }
}
