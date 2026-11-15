pipeline {
    agent any
    tools{
        jdk   "JDK21"
        maven "maven3.9"
    }
    environment {
        SNAP_REPO = "vprofile-snapshot"
        RELEASE_REPO = "vprofile-release"
        CENTRAL_REPO = "vprofile-maven-central"
        NEXUS_GRP_REPO = "vprofile-maven-group"
        NEXUS_USER = "admin"
        NEXUS_PASS = "Devops@2026"
        NEXUSIP = "172.31.30.233"
        NEXUSPORT = "8081"
        NEXUS_LOGIN = "nexus_login"

    }
    stages {
        stage('installing trivy') {
            steps {
                sh ''' sudo apt-get -y install wget gnupg
                sudo wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null 
                echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
                sudo apt-get update 
                sudo apt-get install -y trivy
                '''
            }
        }
        stage('SAST'){
            steps {
                sh 'sudo mkdir -p reports'
                sh 'trivy fs --format json --exit-code 0 --severity HIGH,CRITICAL --output trivy-results.json .'
            }
        }
        stage('archive scan reports') {
            steps {
                archiveArtifacts artifacts: 'trivy-results.json', fingerprint: true
            }
        }
        // stage('Build') {
        //     steps {
        //         sh 'mvn -s settings.xml -DskipTests install'
        //     }
        // }
    }
}