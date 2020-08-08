resource "google_project_service" "service" {
  for_each = toset(var.project_services)

  project = data.google_project.vault.project_id
  service = each.key

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}