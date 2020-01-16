pipeline {


def GCP_PROJECT_ID=''

    agent {
        kubernetes {
          label "demo-${UUID.randomUUID().toString()}"
          defaultContainer 'jnlp'
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
        imagePullPolicy: IfNotPresent
        ttyEnabled: true
      - name: terraform
        image: surjeet112/terraform:0.20
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
        volumeMounts:
        - name: dockersock
          mountPath: /var/run/docker.sock
      volumes:
      - name: dockersock
        hostPath:
          path: /var/run/docker.sock
    """
        }
    }
    options {

        buildDiscarder(logRotator(numToKeepStr:'1'))
        disableConcurrentBuilds()
    }

    environment {
        SVC_ACCOUNT_KEY = credentials('terraform-auth')
      }

    stages {

    stage("BUILD") {
                steps {
                    script {
                    container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'docker-credentials', passwordVariable: 'docker_pass', usernameVariable: 'docker_user')]){
                        dir('docker_flask') {
                            def commitLabel =  sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                            sh "docker build -t gcr.io/${GCP_PROJECT_ID}/docker-flask:${commitLabel} ."
                            sh "docker push gcr.io/${GCP_PROJECT_ID}/docker-flask:${commitlabel}"
                        }
                      }
                    }
                  }
                }
              }

        stage("TERRAFORM_VALIDATE") {
            steps {
                script {
                container('terrafom'){
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
                container('terraform'){
                    dir('terraform_landscape') {
                        sh 'mkdir -p creds'
                        sh 'echo $SVC_ACCOUNT_KEY | base64 -d > ./creds/serviceaccount.json'
                        sh "./init.sh -var project_id="${var.project_id}" -var region="${var.region}" -var billing_account_id}="${var.billing_account_id}
                        sh "terraform plan -var project_id="${var.project_id}" -var region="${var.region}" -var location="${var.region}-a -out myplan"
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
                container('terraform'){
                    dir('terraform_landscape') {
                        unstash 'terraformplan'
                        sh "terraform apply -input=false myplan"
                        sh "sleep 30"
                    }
                }
            }
        }
        }


        stage("GENERATE DESTROY PLAN") {
            steps {
                script {
                container('terraform'){
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
                container('terraform'){
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
