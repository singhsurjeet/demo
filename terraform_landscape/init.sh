#!/usr/bin/env bash

export project_id="$1"
export region="$2"
export billing_account_id="$3"
export terraform_bucket_name=tf-state-bkup

gcloud auth activate-service-account --key-file=./credentials.json

# Link Billing Account
gcloud beta billing projects link ${project_id} \
  --billing-account ${billing_account_id} --quiet

# Create Remote Bucket to keep `terraform.tfstate` shareable and in sync
gsutil mb \
    -p ${project_id} \
    -l ${region} \
    gs://${terraform_bucket_name}-${project_id}

# Create `backend.tf` configuration file
cat > backend.tf <<-EOF
terraform {
  # Which versions of the Terraform CLI can be used with the configuration
  required_version = "~> 0.12.7"

  # Store Terraform state and the history of all revisions remotely, and protect that state with locks to prevent corruption.
  backend "gcs" {
    # The name of the Google Cloud Storage (GCS) bucket
    bucket  = "${terraform_bucket_name}-${project_id}"
    credentials = "./credentials.json"
  }
}
EOF

# Enable versioning for the Remote Bucket
gsutil versioning set on gs://${terraform_bucket_name}-${project_id}

terraform init --input=false

