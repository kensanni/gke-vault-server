# gke-vault-server
This guide helps with provisioning a multi-node [HashiCorp Vault](https://www.vaultproject.io) cluster on [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine) using [Terraform](https://www.terraform.io/) as the provisioning tool.

**These configurations require Terraform 0.12+!**

## **Prerequisites**
To follow along with this guide, ensure you have the following installed on your machine

1. [Terraform](https://www.terraform.io/) version 0.12 or greater on your machine.
2. [Google Cloud SDK](https://cloud.google.com/sdk), You will need to configure your default application credentials so Terraform can run. It will run against your default project, but all resources are created in the new project that it creates.

## Feature Highlights

- **Vault HA** - The Vault cluster will be provisioned in [multi-server mode](https://www.vaultproject.io/docs/concepts/ha.html) for high availability backed by [Google Cloud Storage](https://cloud.google.com/storage).

- **Production Hardened** - Vault is deployed according to the [production hardening guide](https://www.vaultproject.io/guides/operations/production.html). Please see the [security section](#security) for more information.

- **Auto-Init and Unseal** - Vault is automatically initialized and unsealed at runtime. The unseal keys are encrypted with [Google Cloud KMS](https://cloud.google.com/security-key-management) and stored in [Google Cloud Storage](https://cloud.google.com/storage).

- **Full Isolation** - The Vault cluster is provisioned in it's own Kubernetes cluster in a dedicated GCP project that is provisioned dynamically at runtime. Clients connect to Vault using **only** the load balancer and Vault is treated as a managed external service.

- **Audit Logging** - Audit logging to Stackdriver can be optionally enabled with minimal additional configuration.

## Spinning up the vault infrastructure

1. Clone this repository and change into the repository directory

    ```command
    git clone https://github.com/kensanni/gke-vault-server
    cd gke-vault-server
    ```

2. Create a google cloud storage bucket(GCS) to keep track of terraform state. Replace `NAME_OF_BUCKET` with any name of your choice.
    
    ```command
    export BUCKET_NAME="NAME_OF_BUCKET"
    gsutil mb gs://$BUCKET_NAME
    ```

3. Create terraform config file for initializing terraform backend with google cloud storage bucket.

    ```command
    cat > backend.config <<EOF               
    bucket="$BUCKET_NAME"
    prefix="vault-server"
    EOF
    ```

4. Initialize terraform by running the `terraform init -backend-config=backend.config` command.

    ```command
      terraform init -backend-config=backend.config
    ```
5. Export both your google billing account and org id.

    ```command
    export GOOGLE_BILLING_ACCOUNT_ID="YOUR_GOOGLE_BILLING_ACCOUNT_ID"
    export GOOGLE_ORG_ID="YOUR_GOOGLE_ORG_ID"
    ```
  
   Create a `terraform.tfvars` file containing the exported values.
  
    ```command
    cat > terraform.tfvars <<EOF               
    billing_account="$GOOGLE_BILLING_ACCOUNT_ID"
    org_id="$GOOGLE_ORG_ID"
    EOF
    ```


6. Apply terraform changes by running `terraform apply` command

    ```command
      terraform apply
    ```

    This operation will take some time as it:

    1. Creates a new project
    2. Enables the required services on that project
    3. Creates a bucket for storage
    4. Creates a KMS key for encryption
    5. Creates a service account with the most restrictive permissions to those resources
    6. Creates a GKE cluster with the configured service account attached
    7. Creates a public IP
    8. Generates a self-signed certificate authority (CA)
    9. Generates a certificate signed by that CA
    10. Configures Terraform to talk to Kubernetes
    11. Creates a Kubernetes secret with the TLS file contents
    12. Configures your local system to talk to the GKE cluster by getting the cluster credentials and kubernetes context
    13. Submits the StatefulSet and Service to the Kubernetes API


## Interact with Vault

1. Export environment variables:

    Vault reads these environment variables for communication. Set Vault's address, the CA to use for validation, and the initial root token.

    ```command
      export DECRYPT_CMD="$(terraform output root_token_decrypt_command)"
      export VAULT_ADDR="https://$(terraform output address)"
      export VAULT_TOKEN="$(${SHELL} -c "${DECRYPT_CMD}")"
      export VAULT_CAPATH="$(cd ../ && pwd)/tls/ca.pem"
    ```
2. Enable vault secret and a new secret
    ```command
      vault secrets enable -path=secret -version=2 kv
      vault kv put secret/credentials password=test-data
    ```

3. You can access the vault UI by accessing the value of $VAULT_ADDR on your browser.

## Cleaning Up

```command
  terraform destroy
```

## Credits
This guide modifies [Seth Vargo tutorial](https://github.com/sethvargo/vault-on-gke) on setting up vault server to suit my use case. Credit belongs to [Seth Vargo](https://github.com/sethvargo).