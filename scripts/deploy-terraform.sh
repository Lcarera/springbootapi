#!/bin/bash

set -e

# Complete deployment workflow using Terraform
# This script:
# 1. Builds the application
# 2. Creates and pushes Docker image
# 3. Updates infrastructure with Terraform
# 4. Deploys the new version

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_IMAGE=true
VERSION=""
USE_LATEST=false
TERRAFORM_DIR="terraform"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Complete deployment workflow using Terraform"
    echo ""
    echo "Options:"
    echo "  -v VERSION    Use custom version (default: from build.gradle)"
    echo "  -l            Use 'latest' tag"
    echo "  --no-build    Skip building new image (use existing)"
    echo "  -h            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build and deploy with gradle version"
    echo "  $0 -v 1.2.3          # Build and deploy with custom version"
    echo "  $0 -l                 # Build and deploy with 'latest' tag"
    echo "  $0 --no-build -v 1.0.0  # Deploy existing image version 1.0.0"
    exit 1
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -v)
            VERSION="$2"
            shift 2
            ;;
        -l)
            USE_LATEST=true
            VERSION="latest"
            shift
            ;;
        --no-build)
            BUILD_IMAGE=false
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

# Print header
echo -e "${BLUE}🚀 Starting Terraform-based deployment workflow${NC}"
echo "================================================="

# Change to project root
cd "$(dirname "$0")/.."

# Get project properties
echo -e "${YELLOW}🔍 Extracting project properties...${NC}"
GRADLE_PROPERTIES=$(./gradlew properties -q)
PROJECT_NAME=$(echo "$GRADLE_PROPERTIES" | grep "^name: " | sed "s/name: //" | xargs)
GROUP=$(echo "$GRADLE_PROPERTIES" | grep "^group: " | sed "s/group: //" | xargs)

# Set version if not provided
if [ -z "$VERSION" ]; then
    VERSION=$(echo "$GRADLE_PROPERTIES" | grep "^version: " | sed "s/version: //" | xargs)
    echo -e "${BLUE}📋 Using version from gradle: ${VERSION}${NC}"
else
    echo -e "${BLUE}📋 Using custom version: ${VERSION}${NC}"
fi

# Get gcloud project
GCLOUD_PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$GCLOUD_PROJECT_ID" ]; then
    echo -e "${RED}❌ Error: No gcloud project set. Run: gcloud config set project PROJECT_ID${NC}"
    exit 1
fi

IMAGE_NAME="gcr.io/${GCLOUD_PROJECT_ID}/${GROUP}.${PROJECT_NAME}:${VERSION}"

echo -e "${BLUE}📦 Project: ${PROJECT_NAME}${NC}"
echo -e "${BLUE}🏷️  Version: ${VERSION}${NC}"
echo -e "${BLUE}🐳 Image: ${IMAGE_NAME}${NC}"
echo ""

# Step 1: Build application
echo -e "${YELLOW}🔨 Step 1: Building application...${NC}"
./gradlew build
echo -e "${GREEN}✅ Build completed${NC}"
echo ""

# Step 2: Build and push Docker image (if enabled)
if [ "$BUILD_IMAGE" = true ]; then
    echo -e "${YELLOW}🐳 Step 2: Building and pushing Docker image...${NC}"
    
    # Build Docker image using bootBuildImage
    echo "Building image with bootBuildImage..."
    ./gradlew bootBuildImage --imageName="${GROUP}/${PROJECT_NAME}:${VERSION}"
    
    # Tag for GCR
    echo "Tagging image for GCR..."
    docker image tag "${GROUP}/${PROJECT_NAME}:${VERSION}" "${IMAGE_NAME}"
    
    # Push to GCR
    echo "Pushing to Google Container Registry..."
    docker image push "${IMAGE_NAME}"
    
    echo -e "${GREEN}✅ Docker image build and push completed${NC}"
    echo ""
else
    echo -e "${YELLOW}🐳 Step 2: Skipping image build (using existing image)${NC}"
    echo ""
fi

# Step 3: Deploy with Terraform
echo -e "${YELLOW}🏗️  Step 3: Deploying with Terraform...${NC}"

# Check if terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo -e "${RED}❌ Error: Terraform directory '$TERRAFORM_DIR' not found${NC}"
    exit 1
fi

cd "$TERRAFORM_DIR"

# Initialize Terraform (in case it's first run)
echo "Initializing Terraform..."
terraform init

# Plan the deployment
echo "Planning Terraform deployment..."
terraform plan -var="image_name=${IMAGE_NAME}" -out=tfplan

# Apply the changes
echo "Applying Terraform changes..."
terraform apply tfplan

# Get the service URL
SERVICE_URL=$(terraform output -raw cloud_run_url 2>/dev/null || echo "Not available")

echo -e "${GREEN}✅ Terraform deployment completed${NC}"
echo ""

# Step 4: Verify deployment
echo -e "${YELLOW}🔍 Step 4: Verifying deployment...${NC}"

if [ "$SERVICE_URL" != "Not available" ]; then
    echo -e "${BLUE}🌐 Service URL: ${SERVICE_URL}${NC}"
    echo ""
    
    # Wait a moment for deployment to be ready
    echo "Waiting for service to be ready..."
    sleep 10
    
    # Test basic endpoint
    echo "Testing /hello endpoint..."
    if curl -sf "${SERVICE_URL}/hello" > /dev/null; then
        echo -e "${GREEN}✅ Hello endpoint is responding${NC}"
    else
        echo -e "${YELLOW}⚠️  Hello endpoint test failed (service might still be starting)${NC}"
    fi
    
    # Test profile endpoint
    echo "Testing /hello/profile endpoint..."
    PROFILE_RESPONSE=$(curl -sf "${SERVICE_URL}/hello/profile" 2>/dev/null || echo "")
    if [ -n "$PROFILE_RESPONSE" ]; then
        echo -e "${GREEN}✅ Profile endpoint is responding${NC}"
        echo -e "${BLUE}Profile info:${NC}"
        echo "$PROFILE_RESPONSE" | jq . 2>/dev/null || echo "$PROFILE_RESPONSE"
    else
        echo -e "${YELLOW}⚠️  Profile endpoint test failed (service might still be starting)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not retrieve service URL from Terraform output${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Deployment workflow completed successfully!${NC}"
echo "================================================="
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "${BLUE}   • Application built: ✅${NC}"
echo -e "${BLUE}   • Docker image: ${IMAGE_NAME}${NC}"
echo -e "${BLUE}   • Terraform deployed: ✅${NC}"
echo -e "${BLUE}   • Service URL: ${SERVICE_URL}${NC}"
echo ""
echo -e "${BLUE}🔧 Useful commands:${NC}"
echo "   • View logs: gcloud logs tail --follow --filter=\"resource.type=cloud_run_revision\""
echo "   • Terraform plan: cd terraform && terraform plan"
echo "   • Rollback: cd terraform && terraform apply -var=\"image_name=PREVIOUS_IMAGE\""
echo ""