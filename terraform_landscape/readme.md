
## Pre-reqs

The following setup assumes you have already a Google Profile created.

1. As the first step, go to the [Google Cloud Platform Console](https://console.cloud.google.com/) and sign in or, if you don't already have an account, sign up.
2. Then, [create a new Billing Account](https://cloud.google.com/billing/docs/how-to/manage-billing-account).
3. Finally [create a new project](https://console.cloud.google.com/projectcreate).

4. Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) and read the Terraform getting started guide that follows. This guide will assume basic proficiency with Terraform - it is an introduction to the Google provider.
Now push the image to your private Google Container Registry, so it can be deployed from other locations, such as GKE.
Make sure you have the gsutil on your local box to push the images to gcr.

Install gcloud on macOSX:

```
brew tap caskroom/cask
brew cask install google-cloud-sdk
```
Then, initiate to authenticate
```
gcloud init //Follow instruction to setup your account and makes sure that you have project create in GCP
export PROJECT_ID="$(gcloud config get-value project -q)"
gcloud auth configure-docker
```

Now tag the flask image build earlier to push it to gcr.

`docker tag docker_flask:latest "gcr.io/${PROJECT_ID}/docker_flask:v1"`

Alternatively, the source image is already built and uploaded here: `surjeet112/docker_flask:latest`

Then, simply pull and tag:

```
docker pull surjeet112/docker_flask:latest
docker tag surjeet112/docker_flask:latest "gcr.io/${PROJECT_ID}/docker_flask:v1"
```
Finally, push the Docker image to your private Container Registry:

`docker push "gcr.io/${PROJECT_ID}/docker_flask:v1"`


## Provision GCP infrastructure

Make sure that you have minimum 0.12 version of terraform installed.

Create a service account for terraform to provision the infrastructure.
```
gcloud iam service-accounts create [SA-NAME] \
     --description "[SA-DESCRIPTION]" \
     --display-name "[SA-DISPLAY-NAME]"
 ````

Next, download the keys from the above service account to configure in the terraform provider
```
gcloud iam service-accounts keys create ~/credentials.json \
  --iam-account [SA-NAME]@[PROJECT-ID].iam.gserviceaccount.com
 ```

example:
```
provider "google" {
  credentials = file("credentials.json")
  version = "~> 2.9.0"
  project = var.project_id
  region  = var.region
  zone    = var.location
  ```
Please specify the same credentials for terraform remote state backend. 

Now, execute the  `./init.sh` , which is nothing but a wrapper to set certain confinurations before terraform plan.

Script will create the new bucket for terraform state and create backend configs and enable versioning on the bucket and do the `terraform init`.

Execute `terraform plan` and finally run `terraform apply` to create the GKE infrastructure.

## Deploy docker_flask API

First, configure kubectl to use the newly created cluster

`gcloud container clusters get-credentials <YOUR_CLUSTER_NAME> --region europe-west3`