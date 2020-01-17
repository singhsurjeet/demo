pipeline {


    agent {
        kubernetes {
          label "demo-${UUID.randomUUID().toString()}"
          yaml """
    apiVersion: v1
    kind: Pod
    metadata:
      labels:
        jenkins: jenkins-pipeline
    spec:
      securityContext:
        runAsUser: 0
      containers:
      - name: jnlp
        image: surjeet112/jnlp-slave:3.23-1-alpine
        imagePullPolicy: always
        ttyEnabled: true
      - name: tools
        image: surjeet112/gcloud-tf-helm:latest
        imagePullPolicy: IfNotPresent
        command:
        - cat
        tty: true
      - name: docker
        image: surjeet112/docker:17.03.2-ce-rc1-dind
        imagePullPolicy: IfNotPresent
        command:
        - cat
        tty: true

    """
        }
    }
    options {

        buildDiscarder(logRotator(numToKeepStr:'1'))
        disableConcurrentBuilds()
    }
    parameters {
            string(name: 'project_id', defaultValue: 'demo', description: 'GCP project ID')
            string(name: 'region', defaultValue: 'europe-west3', description: 'GCP region')
            string(name: 'billing_account_id', defaultValue: 'demo', description: 'GCP project billing ID')
        }

    environment {
        SVC_ACCOUNT_KEY = credentials('terraform-auth')
      }

    stages {

    stage("BUILD") {
                steps {
                    script {
                    container('docker') {
                        dir('docker_flask') {
                        docker.withRegistry("https://gcr.io/${project_id}/", 'gcr:demo-gcr-creds') {
                            def commit_id =  sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                             app = docker.build("docker-flask:${commit_id}")
                             app.push("${commit_id}")
                             app.push("latest")
                        }
                      }
                    }
                  }
                }
              }

        stage("TERRAFORM_VALIDATE") {
            steps {
                script {
                container('tools'){
                    dir('terraform_landscape') {
                        sh 'mkdir -p creds'
                        sh 'echo $SVC_ACCOUNT_KEY | base64 -d > ./creds/serviceaccount.json'
                        sh "terraform init"
                        sh "terraform validate -check-variables=true"
                    }
                }
              }
            }
        }

        stage("TF INITIATE & PLAN") {
            steps {
                script {
                container('tools'){
                    dir('terraform_landscape') {
                        sh 'mkdir -p creds'
                        sh 'echo $SVC_ACCOUNT_KEY | base64 -d > ./creds/serviceaccount.json'
                        sh "./init.sh -var project_id="${var.project_id}" -var region="${var.region}" -var billing_account_id}="${var.billing_account_id}
                        sh "terraform plan -var project_id=${var.project_id} -var region=${var.region} -var location=${var.region}-a -out myplan "
                        stash name: 'terraformplan' , includes: 'myplan'
                    }
                }
              }
          }
        }
        stage("APPROVE PLAN") {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input 'Do you want to apply the plan?'
                }
            }
        }

        stage("APPLY") {
            steps {
                script {
                container('tools'){
                    dir('terraform_landscape') {
                        unstash 'terraformplan'
                        sh "terraform apply -input=false myplan"
                        sh "sleep 60"
                    }
                }
            }
        }
        }

        stage("DEPLOY APP"){
                steps {
                  script {
                    container('tools'){
                    sh "gcloud container clusters get-credentials demo-private-cluster --zone ${region}-a --project ${project_id}"
                    sh "kubectl create deployment docker-flask-deploy --image=gcr.io/${project_id}/docker-flask:${commit_id}"
                    sh "kubectl expose deployment docker-flask-deploy --type=LoadBalancer --port 80 --target-port 5000"
                    }
                  }
                }
              }



        stage("GENERATE DESTROY PLAN") {
            steps {
                script {
                container('tools'){
                    dir('terraform') {
                        sh "terraform -destroy"
                    }
                }
            }
        }
        }

        stage("APPROVE DESTROY PLAN") {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input 'Do you want to destroy the env?'
                }
            }
        }
        stage("DESTROYING NOW") {
            steps {
                script {
                container('tools'){
                    dir('terraform') {
                        sh "terraform init"
                        sh "terraform destroy -force"
                    }
                }
            }
        }
    }
}
}
