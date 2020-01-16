## Instructions :

1. [Build Flask docker API](docker_flask/readme.md).

   This step can be skipped if you want as the image is already built and available at `surjeet112/docker-flask:latest`
       
2. [Provision the GKE and GCP infrastrucutre via terraform and deploy the flask API to GKE kubernetes cluster accessible via cloud load balancer](terraform_landscape/readme.md).

3.  For CI/CD and infra provisionig jenkins pipelines, please follow this [guide](jenkins/readme.md).

    Root directory has the actual [Jenkinsfile](Jenkinsfile), which is used to automate the process.



