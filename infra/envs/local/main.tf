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
provider "docker" {
  host = "ssh://rpi-docker"
}

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
resource "docker_volume" "kafka_data"    { name = "kafka_data" }
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

resource "docker_container" "kafka" {
  name    = "kafka"
  image   = "bitnami/kafka:3.7"   # multi-arch (arm64 OK)
  restart = "unless-stopped"

  networks_advanced { name = docker_network.backend.name }

  # KRaft single-node (sin ZooKeeper)
  env = [
    "TZ=Europe/Madrid",
    "BITNAMI_DEBUG=false",
    "KAFKA_ENABLE_KRAFT=yes",
    "KAFKA_CFG_NODE_ID=1",
    "KAFKA_CFG_PROCESS_ROLES=broker,controller",
    "KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093",
    "KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092",
    "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT",
    "KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER",
    "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka:9093",
    "ALLOW_PLAINTEXT_LISTENER=yes"
  ]

  volumes {
    volume_name    = docker_volume.kafka_data.name
    container_path = "/bitnami/kafka"
  }

  healthcheck {
    test     = ["CMD-SHELL", "/opt/bitnami/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list >/dev/null 2>&1 || exit 1"]
    interval = "20s"
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
