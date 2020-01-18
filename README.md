
![](/images/jenkins-tf-gke.png)

## Instructions Manual:

1. [Build Flask docker API](docker_flask/readme.md).

   This step can be skipped if you want as the image is already built and available at `surjeet112/docker-flask:latest`
       
2. [Provision the GKE and GCP infrastrucutre via terraform and deploy the flask API to GKE kubernetes cluster accessible via cloud load balancer](terraform_landscape/readme.md).

## Automated Jenkins CI/CD Pipeline

Make sure to follow some of the intiial guidelines in step 2 to setup your GCP account and pre-requisites.

 For CI/CD and infra provisionig jenkins pipelines, please follow this [guide](jenkins/readme.md).
 Jenkins project will look for [Jenkinsfile](Jenkinsfile), which is used to automate the process.

- Initially, the pipeline will get the GCP service account credentials from Jenkins credential store and build the app and push to GCR registry, it then validates the terraform scripts and create a plan to provision the infrastructure.

![](/images/Picture3.png)

- Once approved, pipeline will provision the GCP and GKE infrastrcuture and deploy the application HELM chart

![](/images/Picture4.png)

- Once the app is acessible over the ExternalIP/Loadbalancer, you can approve to generate the infra destruction plan.
![](/images/Picture5.png)

- If you are fine with the destrucution plan, approve to terminate all the provisioned infrastructure
 
 ![](/images/Picture6.png)
 
