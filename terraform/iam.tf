resource "google_service_account" "temporal_server" {
  account_id   = "temporal-server"
  display_name = "Temporal Server (Cloud Run)"
}

resource "google_service_account" "temporal_ui" {
  account_id   = "temporal-ui"
  display_name = "Temporal UI (Cloud Run)"
}

resource "google_project_iam_member" "server_trace" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.temporal_server.email}"
}

resource "google_secret_manager_secret_iam_member" "server_db_pwd" {
  secret_id = google_secret_manager_secret.db_pwd.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.temporal_server.email}"
}

# Allow the UI service to invoke the internal-only server service.
resource "google_cloud_run_v2_service_iam_member" "ui_invokes_server" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.temporal_server.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.temporal_ui.email}"
}

# Vanilla temporalio/ui can't attach a GCP identity token to its outbound
# gRPC, so the server must allow unauthenticated invocations. Network
# isolation is still provided by INGRESS_TRAFFIC_INTERNAL_ONLY on the server.
resource "google_cloud_run_v2_service_iam_member" "server_public_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.temporal_server.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
