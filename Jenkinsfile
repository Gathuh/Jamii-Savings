pipeline {
    agent any
    
    environment {
        JAVA_HOME = '/usr/lib/jvm/java-25-openjdk-amd64'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
        MI_URL = 'http://localhost:8290'
        APIM_URL = 'https://localhost:9443'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build MI Artifacts') {
            steps {
                sh 'mvn clean install -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.car', fingerprint: true
                }
            }
        }
        
        stage('Start Infrastructure') {
            steps {
                sh 'docker compose down -v || true'
                sh 'docker compose up -d'
                sh 'chmod +x scripts/*.sh'
                sh './scripts/wait-for-services.sh'
            }
        }
        
        stage('Deploy to MI') {
            steps {
                sh '''
                    echo "Waiting for MI to detect CAR file..."
                    sleep 30
                    curl -s -u admin:admin http://localhost:9201/management/applications | grep -q "test" || exit 1
                    echo "MI deployment verified"
                '''
            }
        }
        
        stage('Run MI Tests') {
            steps {
                sh './scripts/run-tests.sh'
            }
        }
        
        stage('Deploy APIs to APIM') {
            steps {
                sh './scripts/deploy-apis.sh'
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                echo 'Deploying to Staging environment...'
                sh '''
                    export ENV_NAME="staging"
                    # apictl add env staging --apim https://staging-apim:9443
                    # apictl login staging -u admin -p admin -k
                    # ./scripts/deploy-apis.sh
                    echo "Staging deployment placeholder"
                '''
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
                echo 'Deploying to Production environment...'
                sh '''
                    export ENV_NAME="production"
                    # apictl add env production --apim https://prod-apim:9443
                    # apictl login production -u $PROD_USER -p $PROD_PASS -k
                    # ./scripts/deploy-apis.sh
                    echo "Production deployment placeholder"
                '''
            }
        }
    }
    
    post {
        always {
            sh 'docker compose down -v || true'
            sh 'docker system prune -f || true'
        }
        success {
            echo 'Pipeline completed successfully'
        }
        failure {
            echo 'Pipeline failed - check logs for details'
        }
    }
}
