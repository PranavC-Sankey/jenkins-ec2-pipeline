pipeline {
    agent any

    parameters {
        string(name: 'DEPLOY_VERSION', defaultValue: 'v1', description: 'Deployment version label')
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Git branch to deploy')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
    }

    environment {
        REMOTE_USER = 'ubuntu'
        REMOTE_HOST = '13.221.163.36'
        SSH_KEY_ID = 'ec2-ssh'
        REMOTE_DIR = "/home/ubuntu/deployments/${params.ENV}"
        PORT = '8080'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: "${params.BRANCH_NAME}"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/PranavC-Sankey/jenkins-ec2-pipeline-demo.git',
                        credentialsId: 'github-creds'
                    ]]
                ])
            }
        }

        stage('Deploy') {
            steps {
                sshagent (credentials: [env.SSH_KEY_ID]) {
                    script {
                        def releaseName = "${params.DEPLOY_VERSION}"
                        def targetDir = "${env.REMOTE_DIR}/current"
                        def backupDir = "${env.REMOTE_DIR}/previous"

                        // Create env directories
                        sh """
                            ssh -o StrictHostKeyChecking=no ${env.REMOTE_USER}@${env.REMOTE_HOST} '
                                mkdir -p ${targetDir}
                            '
                        """

                        // Backup for prod
                        if (params.ENV == 'prod') {
                            sh """
                                ssh ${env.REMOTE_USER}@${env.REMOTE_HOST} '
                                    rm -rf ${backupDir} && cp -r ${targetDir} ${backupDir}
                                '
                            """
                        }

                        // SCP files
                        sh """
                            scp -o StrictHostKeyChecking=no -r * ${env.REMOTE_USER}@${env.REMOTE_HOST}:${targetDir}
                        """

                        // Restart http-server
                        sh """
                            ssh ${env.REMOTE_USER}@${env.REMOTE_HOST} '
                                pkill -f "http-server .* ${targetDir}" || true
                                npx http-server ${targetDir} -p ${env.PORT} > /dev/null 2>&1 &
                            '
                        """
                    }
                }
            }
        }

        stage('Verify') {
            steps {
                script {
                    def result = sh (
                        script: "curl -s -o /dev/null -w \"%{http_code}\" http://${env.REMOTE_HOST}:${env.PORT} || echo '000'",
                        returnStdout: true
                    ).trim()

                    if (result != "200") {
                        if (params.ENV == 'prod') {
                            echo "Deployment failed — rolling back!"
                            sshagent (credentials: [env.SSH_KEY_ID]) {
                                sh """
                                    ssh ${env.REMOTE_USER}@${env.REMOTE_HOST} '
                                        rm -rf ${env.REMOTE_DIR}/current
                                        cp -r ${env.REMOTE_DIR}/previous ${env.REMOTE_DIR}/current
                                        pkill -f "http-server .* ${env.REMOTE_DIR}/current" || true
                                        npx http-server ${env.REMOTE_DIR}/current -p ${env.PORT} > /dev/null 2>&1 &
                                    '
                                """
                            }
                        } else {
                            error("Deployment failed (non-200 response), skipping rollback for non-prod")
                        }
                    } else {
                        echo "Deployment successful! Status 200 received."
                    }
                }
            }
        }
    }
}
