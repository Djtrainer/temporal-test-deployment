variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "temporal_image" {
  type    = string
  default = "temporalio/auto-setup:1.24.2"
}

variable "temporal_ui_image" {
  type    = string
  default = "temporalio/ui:2.27.2"
}

variable "otel_image" {
  type        = string
  description = "Artifact Registry image for the otel-collector sidecar"
}
