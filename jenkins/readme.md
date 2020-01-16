## CI/CD -- Jenkins

# Pre-requisite

1. Make sure that you have a kubernetes cluster up and running. On local mac, you can use docker-desktop cluster.

# Installing the jenkins helm chart on your cluster with the required plugins.

Run the helm command locally and follow the instructions to login to your jenkins box

`helm install --name my-release stable/jenkins`

Incase, If you already have the jenkins instance upa and running. Goa head and configure the credentials for Docker repository and GCP service account with below plugins.

### Configure credentials in jenkins
In the Jenkins UI, navigate to Credentials > System > Global Credentials then click Add Credentials, then:
- From the Kind drop down select Secret text.
- Leave the Scope as Global
- Specify the ID of `terraform-auth`

Use base64 to encode the service account credentials file. This converts the multi-line JSON file into a single large string that we can copy and paste into the secret.
Copy the entire string and paste it into the Secret box, then click OK.

`base64 -w0 ./creds/serviceaccount.json`

Plus, follow this for configuring access to GCR repo. [guide](https://medium.com/google-cloud/how-to-push-docker-image-to-google-container-registry-gcr-through-jenkins-job-52b9d5ce9f7f) on how to push images to GCR from jenkins.

Once done, you can now simply go-ahead and create a new multi branch pipeline project and cofigure your git repository after adding your ssh key in credentials.
[Guide](https://github.com/gitbucket/gitbucket/wiki/Setup-Jenkins-Multibranch-Pipeline-and-Organization)











