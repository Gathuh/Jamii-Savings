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
                    echo "Waiting for MI to deploy CAR file..."
                    for i in $(seq 1 12); do
                        echo "Attempt $i/12 - Checking MI deployment..."
                        
                        # Check if APIs are responding
                        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8290/accounts/ACC001/balance 2>/dev/null || echo "000")
                        echo "AccountBalanceAPI response code: $HTTP_CODE"
                        
                        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ] || [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "401" ]; then
                            echo "MI deployment verified - APIs are responding"
                            exit 0
                        fi
                        
                        echo "Not ready yet, waiting 10s..."
                        sleep 10
                    done
                    echo "ERROR: MI deployment failed"
                    docker logs jamii-mi --tail 50
                    exit 1
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
                branch 'production'
            }
            steps {
                echo 'Deploying to Production environment...'
                sh '''
                    export ENV_NAME="production"
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
