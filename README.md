# Temporal on GCP — Test Deployment

Minimal scaffolding to run Temporal on Cloud Run with Cloud SQL (Postgres)
and traces exported to Cloud Trace via an OTel Collector sidecar.

## Architecture

```
                 ┌──────────────────────────────────────┐
                 │            Cloud Run                 │
   user ───►  ┌──┤  temporal-ui   (public, 8080)        │
              │  │     │ gRPC                            │
              │  │     ▼                                 │
              │  │  temporal-server (internal, 7233)    │
              │  │     │       │                         │
              │  │     │       └──► otel-collector ──► Cloud Trace
              │  │     ▼                                 │
              │  └─────┼─────────────────────────────────┘
              │        │ (VPC connector, private IP)
              │        ▼
              │  ┌──────────────────┐
              │  │  Cloud SQL       │
              │  │  Postgres 15     │
              │  └──────────────────┘
```

Two Cloud Run services (server + UI), one multi-container revision on the
server (Temporal + otel-collector sidecar), Cloud SQL via private IP through
a Serverless VPC Access connector.

## Layout

```
terraform/        Infra: VPC, Cloud SQL, Cloud Run, IAM, Secret Manager
docker/
  otel-collector/ Custom image with the Cloud Trace exporter config baked in
Makefile          tf apply / image build helpers
```

## Bootstrap

```
gcloud config set project <PROJECT_ID>
gcloud services enable run.googleapis.com sqladmin.googleapis.com \
  servicenetworking.googleapis.com vpcaccess.googleapis.com \
  cloudtrace.googleapis.com secretmanager.googleapis.com \
  artifactregistry.googleapis.com

make otel-image      # builds + pushes the otel sidecar image
make tf-apply        # provisions everything
```

After apply, the UI URL is in `terraform output temporal_ui_url`.

## Notes

- `temporalio/auto-setup` runs all four Temporal services in one container;
  fine for testing, not for prod scale.
- `min_instances = 1` on the server to avoid cold-start gRPC timeouts.
- Server ingress is internal-only; UI reaches it through the VPC connector.
- Postgres password lives in Secret Manager and is mounted as an env ref.
