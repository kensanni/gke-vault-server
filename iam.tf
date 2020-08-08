########################################################
## Create a service account to be used by vault       ##
##          kubernetes cluster                        ##
########################################################

resource "google_service_account" "vault-server" {
  account_id = "vault-server"
  display_name = "Vault Server"
  project = data.google_project.vault.project_id
}

########################################################
## Assign pre-defined default roles to the service    ##
##  account created                                   ##
########################################################
resource "google_project_iam_member" "service-account" {
  for_each = toset(var.service_account_iam_roles)

  project  = data.google_project.vault.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.vault-server.email}"
}

########################################################
## Assign custom roles to the existing roles defined  ##
##  in the service-account created                    ##
########################################################
resource "google_project_iam_member" "service-account-custom" {
  for_each = toset(var.service_account_custom_iam_roles)

  project  = data.google_project.vault.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.vault-server.email}"
}
