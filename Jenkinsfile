pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Terraform action to perform')
        string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS Region to deploy to')
        string(name: 'SSH_KEY_CREDENTIAL_ID', defaultValue: 'monitoring-ssh-key', description: 'Jenkins credential ID for the EC2 SSH private key')
        string(name: 'EC2_KEY_PAIR_NAME', defaultValue: 'monitoring-system-key', description: 'Name of the EC2 Key Pair in AWS')
        string(name: 'GIT_REPO_URL', defaultValue: 'https://github.com/amrendra-25tech/Tool-infra.git', description: 'Git repository containing this code (for ASG bootstrap)')
        string(name: 'GIT_REPO_BRANCH', defaultValue: 'main', description: 'Git branch to pull for ASG bootstrap')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        TF_DIR                = 'terraform'
        ANSIBLE_DIR           = 'ansible'
    }

    stages {
        stage('Initialize & Validate') {
            steps {
                dir("${env.TF_DIR}") {
                    sh 'terraform init -reconfigure'
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${env.TF_DIR}") {
                    script {
                        if (params.ACTION == 'apply') {
                            sh "terraform plan -var='aws_region=${params.AWS_REGION}' -var='key_name=${params.EC2_KEY_PAIR_NAME}' -var='git_repo_url=${params.GIT_REPO_URL}' -var='git_repo_branch=${params.GIT_REPO_BRANCH}' -out=tfplan"
                        } else {
                            sh "terraform plan -destroy -var='aws_region=${params.AWS_REGION}' -var='key_name=${params.EC2_KEY_PAIR_NAME}' -var='git_repo_url=${params.GIT_REPO_URL}' -var='git_repo_branch=${params.GIT_REPO_BRANCH}' -out=tfplan"
                        }
                    }
                }
            }
        }

        stage('Terraform Apply/Destroy') {
            steps {
                dir("${env.TF_DIR}") {
                    sh "terraform apply -auto-approve tfplan"
                }
            }
        }

        stage('Configure Monitored Application (Ansible)') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    // Extract output parameters from Terraform
                    def bastionPublicIp = ""
                    def albDnsName = ""
                    
                    dir("${env.TF_DIR}") {
                        bastionPublicIp = sh(script: "terraform output -raw bastion_public_ip", returnStdout: true).trim()
                        albDnsName = sh(script: "terraform output -raw alb_dns_name", returnStdout: true).trim()
                    }

                    // Dynamically generate the Ansible inventory file
                    dir("${env.ANSIBLE_DIR}") {
                        writeFile file: 'inventory.ini', text: """
[bastion]
bastion-host ansible_host=${bastionPublicIp} ansible_user=ec2-user

[bastion:vars]
loki_endpoint=${albDnsName}:3100
"""

                        // Execute the Ansible Playbook for Bastion configuration using the private key from Jenkins credentials
                        withCredentials([sshUserPrivateKey(credentialsId: params.SSH_KEY_CREDENTIAL_ID, keyFileVariable: 'SSH_KEY_FILE')]) {
                            sh "ansible-playbook -i inventory.ini playbooks/bastion.yml --private-key=${SSH_KEY_FILE} -u ec2-user"
                        }
                    }
                }
            }
        }

        stage('Deployment Summary') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    def albDnsName = ""
                    dir("${env.TF_DIR}") {
                        albDnsName = sh(script: "terraform output -raw alb_dns_name", returnStdout: true).trim()
                    }
                    echo "=========================================================="
                    echo " DEPLOYMENT SUCCESSFUL"
                    echo "=========================================================="
                    echo " Grafana Dashboard Link: http://${albDnsName}"
                    echo " Loki Push Endpoint: http://${albDnsName}:3100"
                    echo " Note: The Autoscaling Group private instances mount EFS"
                    echo "       and configure Grafana/Prometheus/Loki on boot."
                    echo "=========================================================="
                }
            }
        }
    }

    post {
        always {
            // Clean up temporary plan files
            dir("${env.TF_DIR}") {
                sh 'rm -f tfplan'
            }
            dir("${env.ANSIBLE_DIR}") {
                sh 'rm -f inventory.ini'
            }
        }
    }
}
