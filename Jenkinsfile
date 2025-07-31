pipeline {
    agent any
    
    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Enter the branch to build')
        string(name: 'TARGET_ENVIRONMENT', defaultValue: 'prod', description: 'Target environment (e.g., dev, staging, prod)')
        string(name: 'VERSION', defaultValue: 'v1.0.0', description: 'Deployment version label')
    }
    
    environment {
        PEM_KEY_PATH = 'C:\\Program Files\\Jenkins\\Todo App Server Key.pem'
        EC2_USER = 'ubuntu'
        EC2_HOST = '12.456.31.344'
REPO_URL = 'https://github.com/myuname/my repo.git'
        REMOTE_DEPLOY_DIR = '/tmp/static-build'
        NGINX_ROOT_DIR = '/var/www/html'
        GIT_BASH = "C:\\Program Files\\Git\\bin\\bash.exe"
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                git branch: "${params.BRANCH_NAME}", url: "${env.REPO_URL}"
            }
        }
        
        stage('Make Deploy Script Executable') {
            steps {
                bat '''
"%GIT_BASH%" -c "chmod +x ./deploy.sh"
                '''
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                bat '''
"%GIT_BASH%" -c "./deploy.sh deploy"
                '''
            }
        }
    }
    
    post {
        success {
            echo "✅ Deployment successful from branch: ${params.BRANCH_NAME}"
            echo "🎯 Target Environment: ${params.TARGET_ENVIRONMENT}"
            echo "📋 Version: ${params.VERSION}"
        }
        
        failure {
            echo "❌ Deployment failed, attempting rollback..."
            bat '''
"%GIT_BASH%" -c "./deploy.sh rollback"
            '''
        }
    }
}