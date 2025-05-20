terraform {
  required_providers {
    gitlab = {
      source = "hashicorp/gitlab"
      version = "18.0.0"
    }
  }
}

variable "GITLAB_TOKEN" {
  type = string
  sensitive = true
}

variable "RENOVATE_WEBHOOK_URL" {
  type = string
  sensitive = true
}

variable "RENOVATE_WEBHOOK_SECRET" {
  type = string
  sensitive = true
}

provider "gitlab" {
  # Configuration options
  base_url = "https://gitlab.milanchis.com/api/v4/"
  token = var.GITLAB_TOKEN
}
