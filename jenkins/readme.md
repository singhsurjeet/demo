## CI/CD -- Jenkins

### Pre-requisite

- Jenkins server up and runinng
- Kubernetes cluster to schedule CI/CD workloads.

Alternatively, you can deploy the jenkins on you local minikube or docker-desktop cluster as below.

### Installing the jenkins helm chart on your cluster with the required plugins.

Run the helm command locally and follow the instructions to login to your jenkins box

```
helm init
helm install --name jenkins-demo stable/jenkins
```

Incase, If you already have the jenkins instance up and running. Go head and configure the credentials for GIT-SSH-KEY and GCP service account.
Makes sure that you have all jenkins plugins pre-installed. You can also specify this in the values.yml file of your helm chart.
```
kubernetes:1.2
workflow-aggregator:2.5
workflow-job:2.17
credentials-binding:1.15
git:3.7.0
ghprb:1.40.0
blueocean:1.4.1
docker Pipeline
Declarative Jenkins
sshagent
```

### Configure credentials in jenkins
In the Jenkins UI, navigate to Credentials > System > Global Credentials then click Add Credentials, then:
- From the Kind drop down select Secret text.
- Leave the Scope as Global
- Specify the ID of `terraform-auth`

Use base64 to encode the service account credentials file. This converts the multi-line JSON file into a single large string that we can copy and paste into the secret.
Copy the entire string and paste it into the Secret box, then click OK.

`base64 ./credentials.json > credentials.json`

Plus, follow the configuration access to GCR repo if you are using GCR plugins in jenkins. [Guide](https://medium.com/google-cloud/how-to-push-docker-image-to-google-container-registry-gcr-through-jenkins-job-52b9d5ce9f7f) on how to push images to GCR from jenkins.

Alternaively you can login from `docker login` as shown in pipeline.

Please make sure that you have configured the kubernetes cloud in your jenkins config.

![](/images/k8scloud.png)

Once done, you can now simply go-ahead and [configure](https://github.com/gitbucket/gitbucket/wiki/Setup-Jenkins-Multibranch-Pipeline-and-Organization) a new multi branch pipeline project and cofigure your git repository after adding your ssh key in jenkins credentials.

Once you see your branches in jenkins project. Click on build with parameters to specify all the params and click on build.

![](/images/Picture2.png)










