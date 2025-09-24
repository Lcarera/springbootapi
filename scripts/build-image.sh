#!/bin/bash

set -e

# Script to build Docker image using Spring Boot's bootBuildImage task
# Usage: 
#   ./build-image.sh                    # Use build.gradle version
#   ./build-image.sh -l                 # Use 'latest' tag
#   ./build-image.sh -v VERSION         # Use custom version
# Examples: 
#   ./build-image.sh -v 1.0.0
#   ./build-image.sh -l

VERSION=""
USE_LATEST=false
USE_GRADLE_VERSION=true

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
    echo "  -h            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                # Use build.gradle version"
    echo "  $0 -l             # Use 'latest' tag"
    echo "  $0 -v 1.0.0       # Use custom version"
    exit 1
}

# Parse command line options
while getopts "v:lh" opt; do
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

echo "📋 Extracted project name: ${PROJECT_NAME}"
echo "📋 Extracted group: ${GROUP}"

echo "🚀 Building Docker image for ${PROJECT_NAME}"
echo "📦 Version: ${VERSION}"
echo "🏷️  Group: ${GROUP}"
echo ""

# Change to project root directory (assuming script is in scripts/ subdirectory)
cd "$(dirname "$0")/.."

echo "🔨 Running Gradle bootBuildImage task..."
IMAGE_NAME="${GROUP}/${PROJECT_NAME}:${VERSION}"
# Build the Docker image with the specified version
if [ "$USE_GRADLE_VERSION" = true ]; then
    echo "🔧 Using default version from build.gradle: ${VERSION}"
    ./gradlew bootBuildImage
else
    echo "🔧 Setting custom version: ${VERSION}"
    ./gradlew bootBuildImage --imageName="${IMAGE_NAME}"
fi

echo ""
echo "✅ Docker image build completed successfully!"
echo "🐳 Image name: ${IMAGE_NAME}"
echo ""
echo "To run the container:"
echo "docker run -p 8080:8080 ${IMAGE_NAME}"
