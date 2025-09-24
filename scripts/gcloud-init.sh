#!/bin/bash

# Initialize gcloud
gcloud init

# Login
gcloud auth login

# Set project
gcloud config set project $PROJECT_ID

# Enable Cloud Run and Container Registry APIs
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Configure Docker to use gcloud as credential helper
gcloud auth configure-docker