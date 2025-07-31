#!/bin/bash
 
# Deploy script for EC2 deployment
# Usage: ./deploy.sh <action> [rollback_dir]
# Actions: deploy, rollback
 
ACTION=$1
ROLLBACK_DIR=$2
 
# Convert Windows PEM key path to Unix style for Git Bash
PEM_KEY_UNIX=$(echo "$PEM_KEY_PATH" | sed 's|C:|/c|g' | sed 's|\\|/|g')
 
echo "🚀 Starting deployment process..."
echo "Action: $ACTION"
echo "Branch: $BRANCH_NAME"
echo "Environment: $TARGET_ENVIRONMENT" 
echo "Version: $VERSION"
echo "PEM Key: $PEM_KEY_UNIX"
 
# Set PEM key permissions
chmod 400 "$PEM_KEY_UNIX"
 
if [ "$ACTION" = "deploy" ]; then
    echo "📦 Creating backup of current deployment..."
    ssh -o StrictHostKeyChecking=no -i "$PEM_KEY_UNIX" $EC2_USER@$EC2_HOST "
        sudo mkdir -p /tmp/rollback-$TARGET_ENVIRONMENT &&
        sudo rm -rf /tmp/rollback-$TARGET_ENVIRONMENT/* &&
        sudo cp -r $NGINX_ROOT_DIR/* /tmp/rollback-$TARGET_ENVIRONMENT/ 2>/dev/null || echo 'No existing files to backup'
    "
    
    echo "📤 Uploading static files..."
    scp -o StrictHostKeyChecking=no -i "$PEM_KEY_UNIX" -r index.html style.css script.js $EC2_USER@$EC2_HOST:$REMOTE_DEPLOY_DIR/
    
    echo "⚙️ Deploying new build..."
    ssh -o StrictHostKeyChecking=no -i "$PEM_KEY_UNIX" $EC2_USER@$EC2_HOST "
        sudo rm -rf $NGINX_ROOT_DIR/* &&
        sudo cp -r $REMOTE_DEPLOY_DIR/* $NGINX_ROOT_DIR/ &&
        echo 'Deployed $VERSION to $TARGET_ENVIRONMENT on \$(date)' | sudo tee $NGINX_ROOT_DIR/VERSION.txt &&
        sudo systemctl restart nginx &&
        echo '✅ Nginx restarted successfully'
    "
    
    echo "✅ Deployment completed successfully!"
 
elif [ "$ACTION" = "rollback" ]; then
    echo "🔄 Rolling back to previous version..."
    ssh -o StrictHostKeyChecking=no -i "$PEM_KEY_UNIX" $EC2_USER@$EC2_HOST "
        sudo rm -rf $NGINX_ROOT_DIR/* &&
        sudo cp -r /tmp/rollback-$TARGET_ENVIRONMENT/* $NGINX_ROOT_DIR/ &&
        echo 'Rolled back on \$(date) from failed deployment' | sudo tee $NGINX_ROOT_DIR/VERSION.txt &&
        sudo systemctl restart nginx &&
        echo '✅ Rollback completed and Nginx restarted'
    "
    
    echo "✅ Rollback completed successfully!"
 
else
    echo "❌ Invalid action: $ACTION"
    echo "Usage: ./deploy.sh <deploy|rollback>"
    exit 1
fi
 