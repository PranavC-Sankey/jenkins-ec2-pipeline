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
        EC2_HOST = '13.221.163.36'
        REPO_URL = 'https://github.com/PranavC-Sankey/jenkins-ec2-pipeline.git'
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
        
        stage('Deploy to EC2') {
            steps {
                bat '''
                    echo "Starting deployment process..."
                    
                    "%GIT_BASH%" -c " chmod 400 '%PEM_KEY_PATH%' echo '📦 Backup current deployment...' ssh -o StrictHostKeyChecking=no -i '%PEM_KEY_PATH%' %EC2_USER%@%EC2_HOST% ' sudo mkdir -p /tmp/rollback-%TARGET_ENVIRONMENT% && sudo rm -rf /tmp/rollback-%TARGET_ENVIRONMENT%/* && sudo cp -r %NGINX_ROOT_DIR%/* /tmp/rollback-%TARGET_ENVIRONMENT%/ '  echo '📤 Uploading build...' scp -o StrictHostKeyChecking=no -i '%PEM_KEY_PATH%' -r dist/* %EC2_USER%@%EC2_HOST%:%REMOTE_DEPLOY_DIR%/  echo '⚙️ Deploying new build...' ssh -o StrictHostKeyChecking=no -i '%PEM_KEY_PATH%' %EC2_USER%@%EC2_HOST% ' sudo rm -rf %NGINX_ROOT_DIR%/* && sudo cp -r %REMOTE_DEPLOY_DIR%/* %NGINX_ROOT_DIR%/ && echo \"Deployed %VERSION% to %TARGET_ENVIRONMENT% on $(date)\" | sudo tee %NGINX_ROOT_DIR%/VERSION.txt && sudo systemctl restart nginx '  echo '✅ Deployment completed successfully!'
                    "
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
                echo "Starting rollback process..."
                
                "%GIT_BASH%" -c "
                    chmod 400 '%PEM_KEY_PATH%' echo '🔄 Rolling back to previous version...' ssh -o StrictHostKeyChecking=no -i '%PEM_KEY_PATH%' %EC2_USER%@%EC2_HOST% ' sudo rm -rf %NGINX_ROOT_DIR%/* && sudo cp -r /tmp/rollback-%TARGET_ENVIRONMENT%/* %NGINX_ROOT_DIR%/ && echo \"Rolled back on $(date)\" | sudo tee %NGINX_ROOT_DIR%/VERSION.txt && sudo systemctl restart nginx' echo '✅ Rollback completed!'
                "
            '''
        }
    }
}