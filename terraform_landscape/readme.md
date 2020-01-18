
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

`docker tag docker_flask:latest "gcr.io/${PROJECT_ID}/docker-flask:v1"`

Alternatively, the source image is already built and uploaded here: `surjeet112/docker-flask:latest`

Then, simply pull and tag:

```
docker pull surjeet112/docker-flask:latest
docker tag surjeet112/docker_flask:latest "gcr.io/${PROJECT_ID}/docker-flask:v1"
```
Finally, push the Docker image to your private Container Registry:

`docker push "gcr.io/${PROJECT_ID}/docker-flask:v1"`


## Provision GCP infrastructure

Ensure the required APIs are enabled:
```
gcloud services enable storage-api.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudbilling.googleapis.com
```
Make sure that you have minimum 0.12.19 version of terraform installed.

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
Please specify the same credentials for terraform remote state backend and make sure to update the below variables in `init.sh` and `variables.sh`

```
TF_PROJECT_ID="<>
TF_BILLING_ACCOUNT_ID="<>"

variable "project_id" {
  default = "quixotic-hash-265113"
}

```

Now, execute the  `./init.sh` , which is nothing but a wrapper to set certain confinurations before terraform plan.

Script will create the new bucket for terraform state and create backend configs and enable versioning on the bucket and do the `terraform init`.

Execute `terraform plan` and finally run `terraform apply` to create the GKE infrastructure.

## Deploy docker_flask API

First, configure kubectl to use the newly created cluster, update project_id accordingly.

`gcloud container clusters get-credentials demo-private-cluster --zone europe-west3-a --project quixotic-hash-265113`

Use the kubectl create command to create a Deployment named `docker-flask-deploy` on your cluster:

`kubectl create deployment docker-flask-deploy --image=gcr.io/${PROJECT_ID}/docker-flask:v1 `

Next, we need to expose the app to be accessible publicly

`
kubectl expose deployment docker-flask-deploy --type=LoadBalancer --port 80 --target-port 5000
`

This will take approximately a 1-2 minute to assign an external IP address to the service. You can follow the progress by running:

`kubectl get svc -w`

App should now be available over EXTERNAL-IP

`open http://EXTERNAL-IP`

Alternativey, you can use `helm charts` to manage your deployments. Make sure to install the tiller on GCP or local cluster before running any helm commands for the first time.

- Install helm tiller on the GCP cluster once provisioned before running any helm commands

```kubectl --namespace kube-system create sa tiller
# create a cluster role binding for tiller
kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller
```
echo "initialize helm"
- Initialized helm within the tiller service account
`helm init --service-account tiller`
- Updates the repos for Helm repo integration
`helm repo update`

echo "verify helm"

- verify that helm is installed in the cluster
`kubectl get deploy,svc tiller-deploy -n kube-system`


Now, helm can be used to deploy your application charts.

```
helm init --client-only --skip-refresh
helm upgrade --install --wait docker-flask ./docker-flask --set image.tag="${commit_id}" --set project_id="${project_id}"
```

## Cleaning Up

First, delete the Kubernetes Service:

`kubectl delete service docker-flask-deploy`

This will destroy the Load Balancer created during the previous step

Next, to destroy the GKE cluster, run the terraform destroy command:

`terraform destroy`

Further, you may want to delete the bucket and service account created for storing terraform plan.

Alternatively `helm' can be use to deploy and upgrade deployment to cluster.





