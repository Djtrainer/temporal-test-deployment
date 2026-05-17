resource "google_sql_database_instance" "temporal" {
  name                = "temporal-db"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = false

  settings {
    tier              = "db-custom-1-3840"
    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.temporal.id
    }

    backup_configuration {
      enabled = true
    }
  }

  depends_on = [google_service_networking_connection.private_vpc]
}

resource "google_sql_database" "temporal" {
  name     = "temporal"
  instance = google_sql_database_instance.temporal.name
}

resource "google_sql_database" "visibility" {
  name     = "temporal_visibility"
  instance = google_sql_database_instance.temporal.name
}

resource "google_sql_user" "temporal" {
  name     = "temporal"
  instance = google_sql_database_instance.temporal.name
  password = random_password.db.result
}

resource "google_secret_manager_secret" "db_pwd" {
  secret_id = "temporal-db-pwd"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_pwd" {
  secret      = google_secret_manager_secret.db_pwd.id
  secret_data = random_password.db.result
}
