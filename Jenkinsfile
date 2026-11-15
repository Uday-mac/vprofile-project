def COLOR_MAP = [
    'SUCCESS' : 'good',      // Green
    'UNSTABLE' : 'warning',  // Yellow/Orange
    'FAILURE' : 'danger',    // Red
    'ABORTED'  : '#808080'   // Gray (or custom hex code)
]

pipeline {
    agent any
    tools{
        jdk   "JDK21"
        maven "maven3.9"
    }
    colors
    environment {
        SNAP_REPO = "vprofile-snapshot"
        RELEASE_REPO = "vprofile-release"
        CENTRAL_REPO = "vprofile-maven-central"
        NEXUS_GRP_REPO = "vprofile-maven-group"
        NEXUS_USER = "admin"
        NEXUS_PASS = "Devops@2026"
        NEXUSIP = "172.31.30.233"
        NEXUSPORT = "8081"
        NEXUS_LOGIN = "nexuslogin"

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
        stage('Generate SBOM'){
            steps {
                sh '''
            mkdir -p reports

            # Give Jenkins ownership of reports directory
            sudo chown -R $(whoami):$(id -gn) reports

            # Give owner read/write permissions
            chmod -R u+rwX reports

            # Generate CycloneDX SBOM
            trivy fs \
                --format cyclonedx \
                --output reports/sbom-cyclonedx.json \
                .
            '''
            }
        }
        stage('archive SBOM reports') {
            steps {
                archiveArtifacts artifacts: 'reports/sbom-cyclonedx.json', fingerprint: true
            }
        }
        stage('Build') {
            steps {
                sh 'mvn -s settings.xml -DskipTests install'
            }
            post{
                success {
                    echo "Archieve the artifact..."
                    archiveArtifacts artifacts: '**/*.war', fingerprint: true
                }
            }
        }
        stage('Test') {
            steps {
                sh 'mvn -s settings.xml test'
            }
        }
        stage('checkstyle') {
            steps {
                sh 'mvn -s settings.xml checkstyle:checkstyle'
            }
        }
        stage('SonarQube analysis') {
          environment {
            scannerHome = tool 'sonarscanner';
          }
          steps {
          withSonarQubeEnv('sonarserver') {
          sh '''${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=vprofile \
          -Dsonar.projectName=vprofile \
          -Dsonar.projectVersion=1.0 \
          -Dsonar.sources=src/ \
          -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
          -Dsonar.junit.reportPaths=target/surefire-reports/ \
          -Dsonar.jacoco.reportPaths=target/jacoco.exec \
          -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml
          '''
          }
          }
        }
        stage("Quality Gate") {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
                    // true = set pipeline to UNSTABLE, false = don't
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('artifact upload') {
            steps {
                nexusArtifactUploader(
                nexusVersion: 'nexus3',
                protocol: 'http',
                nexusUrl: "${NEXUSIP}:${NEXUSPORT}",
                groupId: 'QA',
                version: "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}",
                repository: "${env.RELEASE_REPO}",
                credentialsId: "${env.NEXUS_LOGIN}",
                artifacts: [
                [artifactId: 'vproapp',
                classifier: '',
                file: 'target/vprofile-v2.war',
                 type: 'war']
        ]
     )
            }
        }
    }
    post {
        always {
            slslackSend channel: '#vprofie',
            color: COLOR_MAP[currentBuild.currentResult] ?: '#808080',
            message: "Find Status of Pipeline:- ${currentBuild.currentResult} ${env.JOB_NAME} ${env.BUILD_NUMBER} ${BUILD_URL}"
        }
    }
}