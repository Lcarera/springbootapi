#!/bin/bash

set -e

# Script to initialize Google Cloud Platform environment
# Usage: ./gcloud-init.sh PROJECT_ID

PROJECT_ID=""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] PROJECT_ID"
    echo ""
    echo "Initialize Google Cloud Platform environment for the project"
    echo ""
    echo "Arguments:"
    echo "  PROJECT_ID        Your Google Cloud Project ID"
    echo ""
    echo "Options:"
    echo "  -h                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 my-gcp-project-123"
    echo "  $0 -h"
    echo ""
    echo "This script will:"
    echo "  - Initialize gcloud CLI"
    echo "  - Login to Google Cloud"
    echo "  - Set the specified project"
    echo "  - Enable Cloud Run and Container Registry APIs"
    echo "  - Configure Docker to use gcloud credentials"
    exit 1
}

# Parse command line options
while getopts "h" opt; do
    case $opt in
        h)
            show_usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_usage
            ;;
    esac
done

# Shift to get positional arguments after options
shift $((OPTIND-1))

# Get PROJECT_ID from first positional argument
PROJECT_ID="$1"

# Validate PROJECT_ID is provided
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: PROJECT_ID is required"
    echo ""
    show_usage
fi

echo "🚀 Initializing Google Cloud Platform environment"
echo "📦 Project ID: ${PROJECT_ID}"
echo ""

# Initialize gcloud
echo "🔧 Step 1: Initializing gcloud CLI..."
gcloud init
echo "✅ gcloud CLI initialized successfully"
echo ""

# Login
echo "🔐 Step 2: Logging in to Google Cloud..."
gcloud auth login
echo "✅ Successfully logged in to Google Cloud"
echo ""

# Set project
echo "🏗️  Step 3: Setting project to ${PROJECT_ID}..."
gcloud config set project $PROJECT_ID
echo "✅ Project set to ${PROJECT_ID}"
echo ""

# Enable Cloud Run and Container Registry APIs
echo "🔌 Step 4: Enabling required APIs..."
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
echo "✅ Enabled Cloud Run and Container Registry APIs"
echo ""

# Configure Docker to use gcloud as credential helper
echo "🐳 Step 5: Configuring Docker authentication..."
gcloud auth configure-docker
echo "✅ Docker configured to use gcloud as credential helper"
echo ""

echo "🎉 Google Cloud Platform initialization completed successfully!"
echo ""
echo "You can now:"
echo "  - Deploy containers to Cloud Run"
echo "  - Push images to Container Registry"
echo "  - Use Docker with gcloud authentication"