
## Pre-reqs

Now push the image to your private Google Container Registry, so it can be deployed from other locations, such as GKE.
Make sure you have the gsutil on your local box to push the images to gcr.

```
gcloud init //Follow instruction to setup your account and makes sure that you have project create in GCP
export PROJECT_ID="$(gcloud config get-value project -q)"
gcloud auth configure-docker
```

Now tag the flask image build earlier to push it to gcr.

`docker tag docker_flask:latest "gcr.io/${PROJECT_ID}/my_docker_flask:v1"`

Alternatively, the source image is already built and uploaded here: `surjeet112/docker_flask:latest`

Simply pull and tag:

```
docker pull surjeet112/docker_flask:latest
docker tag surjeet112/docker_flask:latest "gcr.io/${PROJECT_ID}/my_docker_flask:v1"
```
Finally, push the Docker image to your private Container Registry:

`docker push "gcr.io/${PROJECT_ID}/docker_flask:v1"`

