output "temporal_server_uri" {
  value = google_cloud_run_v2_service.temporal_server.uri
}

output "temporal_ui_url" {
  value = google_cloud_run_v2_service.temporal_ui.uri
}

output "cloudsql_private_ip" {
  value = google_sql_database_instance.temporal.private_ip_address
}
