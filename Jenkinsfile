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
        stage('Build') {
            steps {
                sh 'mvn -s settings.xml -DskipTests install'
            }
        }
    }
}