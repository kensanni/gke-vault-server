terraform {
  required_version = ">= 0.12"

  required_providers {
    google = "~> 3.0"
  }
}

provider  "google" {
  region  = var.region
  project = var.project
  // credentials=file(var.credentials)
}

provider "google-beta" {
  region  = var.region
  project = var.project
}

resource "random_id" "project_random" {
  prefix      = var.project_prefix
  byte_length = "8"
}


resource "google_project" "vault" {
  name = random_id.project_random.hex
  count = var.project != "" ? 0 : 1
  project_id = random_id.project_random.hex
  org_id = var.org_id
  billing_account = var.billing_account
}

data "google_project" "vault" {
  project_id = var.project != "" ? var.project : google_project.vault[0].project_id
}