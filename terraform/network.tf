resource "google_compute_network" "temporal" {
  name                    = "temporal-net"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "temporal" {
  name          = "temporal-subnet"
  region        = var.region
  network       = google_compute_network.temporal.id
  ip_cidr_range = "10.10.0.0/24"
}

resource "google_compute_global_address" "private_ip" {
  name          = "temporal-sql-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.temporal.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.temporal.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}

resource "google_vpc_access_connector" "temporal" {
  name          = "temporal-conn"
  region        = var.region
  network       = google_compute_network.temporal.name
  ip_cidr_range = "10.20.0.0/28"
}
