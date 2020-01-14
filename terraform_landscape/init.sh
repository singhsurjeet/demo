#!/usr/bin/env bash

export TF_PROJECT_ID=""
export TF_REGION="europe-west3"
export TF_BILLING_ACCOUNT_ID=""
export TF_FOLDER=
export BUCKET_NAME=tf-state-bkup

# Link Billing Account
gcloud beta billing projects link ${TF_PROJECT_ID} \
  --billing-account ${TF_BILLING_ACCOUNT_ID}

# Create Remote Bucket to keep `terraform.tfstate` shareable and in sync
gsutil mb \
    -p ${TF_PROJECT_ID} \
    -l ${TF_REGION} \
    gs://${BUCKET_NAME}-${TF_PROJECT_ID}

# Create `backend.tf` configuration file
cat > backend.tf <<-EOF
terraform {
  # Which versions of the Terraform CLI can be used with the configuration
  required_version = "~> 0.12.7"

  # Store Terraform state and the history of all revisions remotely, and protect that state with locks to prevent corruption.
  backend "gcs" {
    # The name of the Google Cloud Storage (GCS) bucket
    bucket  = "${BUCKET_NAME}-${TF_PROJECT_ID}"
    credentials = "credentials.json"
  }
}
EOF

# Enable versioning for the Remote Bucket
gsutil versioning set on gs://${BUCKET_NAME}-${TF_PROJECT_ID}

terraform init

