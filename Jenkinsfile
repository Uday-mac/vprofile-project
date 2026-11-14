pipeline {
    agent any
    tools{
        maven 'maven3'
    }
    stages {
        stage('fetch code') {
            steps {
                git branch: 'jenkins', url: 'https://github.com/Uday-mac/vprofile-project.git'
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean install'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
    }
}