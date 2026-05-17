resource "google_cloud_run_v2_service" "temporal_server" {
  name     = "temporal-server"
  location = var.region
  # ALL because vanilla temporalio/ui cannot attach a GCP identity token to
  # its outbound gRPC, and Cloud Run's "internal" ingress filter does not
  # recognize same-project Cloud Run callers without one. Combined with the
  # allUsers run.invoker binding, this leaves the server publicly reachable
  # by anyone with the URL — acceptable only for short-lived test deploys.
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.temporal_server.email

    scaling {
      min_instance_count = 1
      max_instance_count = 1
    }

    vpc_access {
      connector = google_vpc_access_connector.temporal.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      name  = "temporal"
      image = var.temporal_image

      ports {
        name           = "h2c"
        container_port = 7233
      }

      startup_probe {
        tcp_socket {
          port = 7233
        }
        initial_delay_seconds = 30
        period_seconds        = 10
        failure_threshold     = 60
        timeout_seconds       = 5
      }

      env {
        name  = "DB"
        value = "postgres12"
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name  = "BIND_ON_IP"
        value = "0.0.0.0"
      }
      env {
        name  = "TEMPORAL_BROADCAST_ADDRESS"
        value = "127.0.0.1"
      }
      env {
        name  = "POSTGRES_SEEDS"
        value = google_sql_database_instance.temporal.private_ip_address
      }
      env {
        name  = "POSTGRES_USER"
        value = google_sql_user.temporal.name
      }
      env {
        name = "POSTGRES_PWD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_pwd.secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "DBNAME"
        value = google_sql_database.temporal.name
      }
      env {
        name  = "VISIBILITY_DBNAME"
        value = google_sql_database.visibility.name
      }

      # Temporal Server's built-in OTel exporter → local sidecar.
      env {
        name  = "TEMPORAL_OTEL_EXPORTER_OTLP_ENDPOINT"
        value = "http://localhost:4317"
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "2Gi"
        }
        startup_cpu_boost = true
      }
    }

    containers {
      name  = "otel-collector"
      image = var.otel_image

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.server_db_pwd,
    google_sql_user.temporal,
  ]
}

resource "google_cloud_run_v2_service" "temporal_ui" {
  name     = "temporal-ui"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.temporal_ui.email

    vpc_access {
      connector = google_vpc_access_connector.temporal.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = var.temporal_ui_image

      ports {
        container_port = 8080
      }

      env {
        name  = "TEMPORAL_ADDRESS"
        value = "${replace(google_cloud_run_v2_service.temporal_server.uri, "https://", "")}:443"
      }
      env {
        name  = "TEMPORAL_TLS_SERVER_NAME"
        value = replace(google_cloud_run_v2_service.temporal_server.uri, "https://", "")
      }
      env {
        name  = "TEMPORAL_TLS_ENABLE_HOST_VERIFICATION"
        value = "true"
      }
      env {
        name  = "TEMPORAL_CORS_ORIGINS"
        value = "http://localhost:3000"
      }
    }
  }
}
