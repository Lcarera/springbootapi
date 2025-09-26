#https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build
#https://registry.terraform.io/providers/hashicorp/google/latest/docs
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "sprint-deploy-test"
  region  = "southamerica-west1"
  zone    = "southamerica-west1-c"
}

# Enable required APIs
resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
}

resource "google_project_service" "cloud_build_api" {
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "container_registry_api" {
  service = "containerregistry.googleapis.com"
}

# Cloud Run service
resource "google_cloud_run_service" "springboot_api" {
  name     = "springboot-api"
  location = "southamerica-west1"

  template {
    spec {
      containers {
        image = "gcr.io/sprint-deploy-test/com.gm2dev.springbootapi:1.0.1"
        
        ports {
          container_port = 8080
        }
        
        # Resource limits
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
        
        # Environment variables
        env {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "prod"
        }
      }
    }
    
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
        "run.googleapis.com/cpu-throttling" = "false"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.cloud_run_api]
}

# Allow unauthenticated access
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.springboot_api.name
  location = google_cloud_run_service.springboot_api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Output the service URL
output "cloud_run_url" {
  value = google_cloud_run_service.springboot_api.status[0].url
}
