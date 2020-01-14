terraform {
  # Which versions of the Terraform CLI can be used with the configuration
  required_version = "~> 0.12.7"

  # Store Terraform state and the history of all revisions remotely, and protect that state with locks to prevent corruption.
  backend "gcs" {
    # The name of the Google Cloud Storage (GCS) bucket
    bucket  = "tf-state-bkup-quixotic-hash-265113"
    credentials = "credentials.json"
  }
}
