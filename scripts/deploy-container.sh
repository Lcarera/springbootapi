#!/bin/bash

set -e

# Script to deploy container to Google Cloud Run
# Usage: 
#   ./deploy-container.sh                           # Deploy with defaults
#   ./deploy-container.sh -i IMAGE                  # Deploy specific image
#   ./deploy-container.sh -s SERVICE_NAME           # Deploy with custom service name
#   ./deploy-container.sh -r REGION                 # Deploy to specific region
# Examples: 
#   ./deploy-container.sh
#   ./deploy-container.sh -i gcr.io/my-project/app:1.0.0
#   ./deploy-container.sh -s my-service -r us-central1

# Default values
SERVICE_NAME=""
IMAGE_NAME=""
REGION="southamerica-west1"
PLATFORM="managed"
PORT="8080"
MEMORY="1Gi"
CPU="1"
TIMEOUT="600"
ALLOW_UNAUTHENTICATED=true
ENV_VARS="SPRING_PROFILES_ACTIVE=prod"
# Extract project name and group from Gradle files
PROJECT_NAME=""
GROUP=""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy container to Google Cloud Run"
    echo ""
    echo "Options:"
    echo "  -s SERVICE        Service name (default: project name)"
    echo "  -i IMAGE          Container image (default: gcr.io/PROJECT_ID/group.projectname:latest)"
    echo "  -r REGION         Deployment region (default: southamerica-west1)"
    echo "  -p PORT           Container port (default: 8080)"
    echo "  -m MEMORY         Memory allocation (default: 1Gi)"
    echo "  -c CPU            CPU allocation (default: 1)"
    echo "  -t TIMEOUT        Request timeout in seconds (default: 600)"
    echo "  --no-auth         Disable unauthenticated access (default: allow unauthenticated)"
    echo "  -e ENV_VARS       Environment variables (default: SPRING_PROFILES_ACTIVE=prod)"
    echo "  -h                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                        # Deploy with all defaults"
    echo "  $0 -s my-api                              # Custom service name"
    echo "  $0 -i gcr.io/my-project/app:1.0.0         # Custom image"
    echo "  $0 -r us-central1 -m 2Gi -c 2             # Custom region and resources"
    echo "  $0 -e SPRING_PROFILES_ACTIVE=prod         # Custom environment variables"
    echo ""
    echo "Default image format: gcr.io/PROJECT_ID/group.projectname:latest"
    echo "Note: Requires gcloud to be configured with a project."
    exit 1
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -s)
            SERVICE_NAME="$2"
            shift 2
            ;;
        -i)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -r)
            REGION="$2"
            shift 2
            ;;
        -p)
            PORT="$2"
            shift 2
            ;;
        -m)
            MEMORY="$2"
            shift 2
            ;;
        -c)
            CPU="$2"
            shift 2
            ;;
        -t)
            TIMEOUT="$2"
            shift 2
            ;;
        --no-auth)
            ALLOW_UNAUTHENTICATED=false
            shift
            ;;
        -h)
            show_usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_usage
            ;;
    esac
done

# Change to project root directory
cd "$(dirname "$0")/.."

# Check if gradlew exists
if [ ! -f "./gradlew" ]; then
    echo "❌ Error: gradlew not found in project root"
    exit 1
fi

# Make gradlew executable if it isn't already
chmod +x ./gradlew

echo "🔍 Extracting project properties using Gradle..."

# Extract project properties using gradlew properties
GRADLE_PROPERTIES=$(./gradlew properties -q)

# Extract project name
PROJECT_NAME=$(echo "$GRADLE_PROPERTIES" | grep "^name: " | sed "s/name: //" | xargs)
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Error: Could not extract project name from gradle properties"
    exit 1
fi

# Extract group
GROUP=$(echo "$GRADLE_PROPERTIES" | grep "^group: " | sed "s/group: //" | xargs)
if [ -z "$GROUP" ]; then
    echo "❌ Error: Could not extract group from gradle properties"
    exit 1
fi

# Get current gcloud project ID
GCLOUD_PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$GCLOUD_PROJECT_ID" ]; then
    echo "❌ Error: No gcloud project is currently set. Please run 'gcloud config set project PROJECT_ID' first."
    exit 1
fi

# Set default service name if not provided
if [ -z "$SERVICE_NAME" ]; then
    SERVICE_NAME="$PROJECT_NAME"
fi

# Set default image name if not provided
if [ -z "$IMAGE_NAME" ]; then
    IMAGE_NAME="gcr.io/${GCLOUD_PROJECT_ID}/${GROUP}.${PROJECT_NAME}:latest"
fi

echo "📋 Extracted project name: ${PROJECT_NAME}"
echo "📋 Extracted group: ${GROUP}"
echo ""
echo "🚀 Deploying to Google Cloud Run"
echo "🎯 Project ID: ${GCLOUD_PROJECT_ID}"
echo "🏷️  Service name: ${SERVICE_NAME}"
echo "🐳 Image: ${IMAGE_NAME}"
echo "🌍 Region: ${REGION}"
echo "🔧 Resources: ${CPU} CPU, ${MEMORY} memory"
echo "⏱️  Timeout: ${TIMEOUT}s"
echo "🔐 Unauthenticated access: $([ "$ALLOW_UNAUTHENTICATED" = true ] && echo "ENABLED" || echo "DISABLED")"
echo ""

# Build the gcloud run deploy command
DEPLOY_CMD="gcloud run deploy ${SERVICE_NAME}"
DEPLOY_CMD+=" --image ${IMAGE_NAME}"
DEPLOY_CMD+=" --platform ${PLATFORM}"
DEPLOY_CMD+=" --region ${REGION}"
DEPLOY_CMD+=" --port ${PORT}"
DEPLOY_CMD+=" --memory ${MEMORY}"
DEPLOY_CMD+=" --cpu ${CPU}"
DEPLOY_CMD+=" --timeout ${TIMEOUT}"
DEPLOY_CMD+=" --set-env-vars ${ENV_VARS}"

if [ "$ALLOW_UNAUTHENTICATED" = true ]; then
    DEPLOY_CMD+=" --allow-unauthenticated"
fi

echo "🔨 Running Cloud Run deployment..."
echo "Command: ${DEPLOY_CMD}"
echo ""

# Execute the deployment
eval $DEPLOY_CMD

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment completed successfully!"
    echo "🎉 Service '${SERVICE_NAME}' is now running on Cloud Run"
    echo ""
    echo "Service URL: https://${SERVICE_NAME}-$(echo ${REGION} | tr -d '-').a.run.app"
    echo ""
    echo "To view logs:"
    echo "gcloud logs tail --follow --filter=\"resource.type=cloud_run_revision AND resource.labels.service_name=${SERVICE_NAME}\""
else
    echo ""
    echo "❌ Deployment failed!"
    exit 1
fi
