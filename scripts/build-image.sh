#!/bin/bash

set -e

# Script to build Docker image using Spring Boot's bootBuildImage task
# Usage: 
#   ./build-image.sh                    # Use build.gradle version
#   ./build-image.sh -l                 # Use 'latest' tag
#   ./build-image.sh -v VERSION         # Use custom version
#   ./build-image.sh -p                 # Build and push to GCR
# Examples: 
#   ./build-image.sh -v 1.0.0
#   ./build-image.sh -l
#   ./build-image.sh -p
#   ./build-image.sh -v 2.0.0 -p

VERSION=""
USE_LATEST=false
USE_GRADLE_VERSION=true
PUSH_IMAGE=false

# Extract project name and group from Gradle files
PROJECT_NAME=""
GROUP=""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v VERSION    Use custom version"
    echo "  -l            Use 'latest' tag"
    echo "  -p            Push image to Google Container Registry (GCR)"
    echo "  -h            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Use build.gradle version"
    echo "  $0 -l                     # Use 'latest' tag"
    echo "  $0 -v 1.0.0               # Use custom version"
    echo "  $0 -p                     # Build and push to GCR"
    echo "  $0 -v 2.0.0 -p            # Build custom version and push to GCR"
    echo ""
    echo "Note: Push requires gcloud to be configured with a project."
    echo "      Images are pushed to: gcr.io/PROJECT_ID/group.projectname:version"
    exit 1
}

# Parse command line options
while getopts "v:lph" opt; do
    case $opt in
        v)
            VERSION="$OPTARG"
            USE_GRADLE_VERSION=false
            ;;
        l)
            VERSION="latest"
            USE_LATEST=true
            USE_GRADLE_VERSION=false
            ;;
        p)
            PUSH_IMAGE=true
            ;;
        h)
            show_usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
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

# Set default version if no flags provided
if [ "$USE_GRADLE_VERSION" = true ]; then
    # Extract version from gradle properties
    VERSION=$(echo "$GRADLE_PROPERTIES" | grep "^version: " | sed "s/version: //" | xargs)
    if [ -z "$VERSION" ]; then
        echo "❌ Error: Could not extract version from gradle properties"
        exit 1
    fi
    echo "📋 Extracted version from gradle properties: ${VERSION}"
fi

# Construct the full image name
IMAGE_NAME="${GROUP}/${PROJECT_NAME}:${VERSION}"

echo "📋 Extracted project name: ${PROJECT_NAME}"
echo "📋 Extracted group: ${GROUP}"

echo "🚀 Building Docker image for ${PROJECT_NAME}"
echo "📦 Version: ${VERSION}"
echo "🏷️  Group: ${GROUP}"
echo ""


echo "🔨 Running Gradle bootBuildImage task..."
if [ "$PUSH_IMAGE" = true ]; then
    echo "📤 Push to GCR: ENABLED"
else
    echo "📦 Build only: Push disabled"
fi

# Build the Docker image with the specified version
./gradlew bootBuildImage --imageName="${IMAGE_NAME}"

echo ""
if [ "$PUSH_IMAGE" = true ]; then
    # Get current gcloud project ID
    GCLOUD_PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$GCLOUD_PROJECT_ID" ]; then
        echo "❌ Error: No gcloud project is currently set. Please run 'gcloud config set project PROJECT_ID' first."
        exit 1
    fi
    
    # Create GCR image name: gcr.io/project-id/group.projectname:version
    GCR_IMAGE_NAME="gcr.io/${GCLOUD_PROJECT_ID}/${GROUP}.${PROJECT_NAME}:${VERSION}"
    
    echo "🏷️  Tagging image for Google Container Registry..."
    echo "📤 GCR Image: ${GCR_IMAGE_NAME}"
    
    docker image tag ${IMAGE_NAME} ${GCR_IMAGE_NAME}
    
    echo "🚀 Pushing image to Google Container Registry..."
    docker image push ${GCR_IMAGE_NAME}
    
    echo "✅ Docker image build and push completed successfully!"
    echo "🐳 Local image: ${IMAGE_NAME}"
    echo "📤 GCR image: ${GCR_IMAGE_NAME}"
    echo "🎯 Google Cloud Project: ${GCLOUD_PROJECT_ID}"
else
    echo "✅ Docker image build completed successfully!"
    echo "🐳 Image name: ${IMAGE_NAME}"
    echo "📦 Image available locally"
fi
echo ""
echo "To run the container:"
if [ "$PUSH_IMAGE" = true ]; then
    echo "docker run -p 8080:8080 ${GCR_IMAGE_NAME}"
else
    echo "docker run -p 8080:8080 ${IMAGE_NAME}"
fi
