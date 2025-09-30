variable "project" { 
  default = "sprint-deploy-test"
}

variable "region" {
  default = "southamerica-west1"
}

variable "zone" {
  default = "southamerica-west1-c"
}

variable "service_name" {
  default = "springboot-api"
}

variable "image_name" {
  description = "Full image name including registry, project, and tag"
  type        = string
  default     = ""
}

variable "image_version" {
  default = "1.0.3"
}

locals {
  image_name = var.image_name != "" ? var.image_name : "gcr.io/${var.project}/com.gm2dev.springbootapi:${var.image_version}"
}
