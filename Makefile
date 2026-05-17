PROJECT_ID ?= $(shell gcloud config get-value project)
REGION     ?= us-central1
REPO       ?= temporal
OTEL_IMAGE := $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPO)/otel-collector:latest

.PHONY: ar-repo otel-image tf-init tf-plan tf-apply tf-destroy

ar-repo:
	gcloud artifacts repositories describe $(REPO) --location=$(REGION) >/dev/null 2>&1 || \
	gcloud artifacts repositories create $(REPO) --repository-format=docker --location=$(REGION)

otel-image: ar-repo
	gcloud builds submit docker/otel-collector --tag=$(OTEL_IMAGE)

tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan \
	  -var="project_id=$(PROJECT_ID)" \
	  -var="region=$(REGION)" \
	  -var="otel_image=$(OTEL_IMAGE)"

tf-apply:
	cd terraform && terraform apply \
	  -var="project_id=$(PROJECT_ID)" \
	  -var="region=$(REGION)" \
	  -var="otel_image=$(OTEL_IMAGE)"

tf-destroy:
	cd terraform && terraform destroy \
	  -var="project_id=$(PROJECT_ID)" \
	  -var="region=$(REGION)" \
	  -var="otel_image=$(OTEL_IMAGE)"
