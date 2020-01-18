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
        imagePullPolicy: IfNotPresent
        ttyEnabled: true
      - name: tools
        image: surjeet112/gcloud-tf-helm:latest
        imagePullPolicy: IfNotPresent
        command:
        - cat
        tty: true
      - name: docker
        image: surjeet112/docker:17.03.2-ce-rc1-dind-git
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
    parameters {
            string(name: 'project_id', defaultValue: 'quixotic-hash-265113', description: 'GCP project ID')
            string(name: 'region', defaultValue: 'europe-west3', description: 'GCP region')
            string(name: 'billing_account_id', defaultValue: '0114AF-A8061F-7F222A', description: 'GCP project billing ID')
        }
    environment{
            GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
        }

    stages {

        stage("GET CREDS") {
            steps {
                script {
                    container('docker') {
                        withCredentials([string(credentialsId: 'terraform-auth', variable: 'GCP_SVC_KEY')]) {
                        sh "echo ${GCP_SVC_KEY} > en_creds.json"
                        sh "base64 -d en_creds.json > credentials.json"
                        stash name: "creds", includes: "credentials.json"
                        }
                    }
                }
            }
        }
        
        stage("BUILD & PUBLISH") {
            steps {
                script {
                    container('docker') {
                        dir('docker_flask') {
                        unstash 'creds'
                        def commit_id =  sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                        //sh 'docker login -u _json_key -p "$(cat credentials.json)" https://gcr.io'
                        // sh "docker build -t gcr.io/${PROJECT_ID}/docker-flask:${commit_id} ."
                        // sh "docker push gcr.io/${PROJECT_ID}/docker-flask:${commit_id}"
                    }
                  }
               }
            }
        }

        // stage("TERRAFORM_VALIDATE") {
        //     steps {
        //         script {
        //         container('tools'){
        //             dir('terraform_landscape') {
        //                 sshagent(['github-ssh-key']){
        //                     unstash 'creds'
        //                     sh "terraform init -backend=false"
        //                     sh "terraform validate"
        //                 }
        //             }
        //         }
        //      }
        //   }
        // }
    

        stage("TERRAFORM_PLAN") {
            steps {
                script {
                container('tools'){
                    dir('terraform_landscape') {
                        sshagent(['github-ssh-key']){
                            unstash 'creds'
                            sh "./init.sh ${env.project_id} ${env.region} ${env.billing_account_id}"
                            sh "terraform plan -var project_id=${var.project_id} -var region=${var.region} -var location=${var.region}-a -out myplan "
                            stash name: 'terraformplan' , includes: 'myplan'
                            }
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
                        unstash 'creds'
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
                    unstash 'creds'
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
                        unstash 'creds'
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
                        unstash 'creds'
                        sh "terraform init"
                        sh "terraform destroy -force"
                    }
                }
            }
        }
    }
}
}
