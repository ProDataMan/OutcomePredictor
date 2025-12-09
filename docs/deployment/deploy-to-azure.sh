#!/bin/bash

# Azure Deployment Script for StatShark
# This script deploys the StatShark prediction server to Azure App Service

set -e  # Exit on any error

echo "🦈 StatShark - Azure Deployment Script"
echo "======================================="
echo ""

# Configuration
RESOURCE_GROUP="ProDataMan"  # Using existing resource group for App Service Plan
REGISTRY_RESOURCE_GROUP="statshark-rg"  # Existing resource group for Container Registry
LOCATION="westus"
REGISTRY_NAME="statsharkregistry"  # Using existing Container Registry
APP_SERVICE_PLAN="ASP-ProDataMan-996c"  # Using existing App Service Plan
WEB_APP_NAME="statshark-api"
IMAGE_NAME="statshark-server"
SKU="F1"  # Not used - existing plan already configured

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Installing..."
    brew install azure-cli
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop"
    exit 1
fi

echo "✅ Prerequisites OK"
echo ""

# Check Azure login
echo "🔐 Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "Not logged in. Opening browser for login..."
    az login
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
echo "✅ Logged in to: $SUBSCRIPTION"
echo ""

# Prompt for Odds API Key
if [ -z "$ODDS_API_KEY" ]; then
    echo "⚠️  ODDS_API_KEY environment variable not set"
    read -p "Enter your Odds API key: " ODDS_API_KEY
    if [ -z "$ODDS_API_KEY" ]; then
        echo "❌ Odds API key is required"
        exit 1
    fi
fi

echo ""
echo "🚀 Starting deployment..."
echo ""

# Step 1: Verify Resource Group exists
echo "1️⃣  Verifying resource group: $RESOURCE_GROUP"
if az group exists --name $RESOURCE_GROUP | grep -q true; then
    echo "   ✅ Resource group exists"
else
    echo "   ❌ Resource group $RESOURCE_GROUP not found"
    exit 1
fi
echo ""

# Step 2: Verify Container Registry exists
echo "2️⃣  Verifying Azure Container Registry: $REGISTRY_NAME"
if az acr show --name $REGISTRY_NAME --resource-group $REGISTRY_RESOURCE_GROUP &> /dev/null; then
    echo "   ✅ Using existing Container Registry"
else
    echo "   ❌ Container Registry $REGISTRY_NAME not found in $REGISTRY_RESOURCE_GROUP"
    exit 1
fi
echo ""

# Step 3: Build Docker Image
echo "3️⃣  Building Docker image..."
cd "$(dirname "$0")"
docker build -t $IMAGE_NAME:latest .
echo "✅ Docker image built"
echo ""

# Step 4: Get ACR credentials
echo "4️⃣  Getting registry credentials..."
ACR_LOGIN_SERVER=$(az acr show \
    --name $REGISTRY_NAME \
    --resource-group $REGISTRY_RESOURCE_GROUP \
    --query loginServer -o tsv)

ACR_PASSWORD=$(az acr credential show \
    --name $REGISTRY_NAME \
    --query "passwords[0].value" -o tsv)

echo "   Registry: $ACR_LOGIN_SERVER"
echo ""

# Step 5: Login to ACR
echo "5️⃣  Logging in to Azure Container Registry..."
echo $ACR_PASSWORD | docker login $ACR_LOGIN_SERVER \
    --username $REGISTRY_NAME \
    --password-stdin
echo "✅ Logged in to ACR"
echo ""

# Step 6: Tag and Push Image
echo "6️⃣  Tagging and pushing image to registry..."
docker tag $IMAGE_NAME:latest $ACR_LOGIN_SERVER/$IMAGE_NAME:latest
docker push $ACR_LOGIN_SERVER/$IMAGE_NAME:latest
echo "✅ Image pushed to registry"
echo ""

# Step 7: Verify App Service Plan exists
echo "7️⃣  Verifying App Service Plan: $APP_SERVICE_PLAN"
if az appservice plan show \
    --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "   ✅ Using existing App Service Plan"
    az appservice plan show \
        --name $APP_SERVICE_PLAN \
        --resource-group $RESOURCE_GROUP \
        --output table
else
    echo "   ❌ App Service Plan $APP_SERVICE_PLAN not found in $RESOURCE_GROUP"
    exit 1
fi
echo ""

# Step 8: Create Web App
echo "8️⃣  Creating Web App: $WEB_APP_NAME"
if az webapp show \
    --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "   Web App already exists, updating configuration..."
else
    az webapp create \
        --resource-group $RESOURCE_GROUP \
        --plan $APP_SERVICE_PLAN \
        --name $WEB_APP_NAME \
        --deployment-container-image-name $ACR_LOGIN_SERVER/$IMAGE_NAME:latest \
        --output table
fi
echo ""

# Step 9: Configure Container Settings
echo "9️⃣  Configuring container settings..."
az webapp config container set \
    --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --docker-custom-image-name $ACR_LOGIN_SERVER/$IMAGE_NAME:latest \
    --docker-registry-server-url https://$ACR_LOGIN_SERVER \
    --docker-registry-server-user $REGISTRY_NAME \
    --docker-registry-server-password $ACR_PASSWORD \
    --output table
echo ""

# Step 10: Configure Environment Variables
echo "🔟 Configuring environment variables..."
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --settings \
        ENV=production \
        PORT=8080 \
        ODDS_API_KEY=$ODDS_API_KEY \
        ESPN_BASE_URL=https://site.api.espn.com/apis/site/v2/sports/football/nfl \
        ODDS_API_BASE_URL=https://api.the-odds-api.com/v4 \
        SERVER_BASE_URL=https://$WEB_APP_NAME.azurewebsites.net/api/v1 \
        CACHE_EXPIRATION=21600 \
        WEBSITES_PORT=8080 \
    --output table
echo ""

# Step 11: Enable HTTPS Only
echo "1️⃣1️⃣  Enabling HTTPS..."
az webapp update \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --https-only true \
    --output table
echo ""

# Step 12: Restart App
echo "1️⃣2️⃣  Restarting web app..."
az webapp restart \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --output table
echo ""

# Get the URL
APP_URL="https://$WEB_APP_NAME.azurewebsites.net"

echo ""
echo "✅ Deployment Complete!"
echo "===================="
echo ""
echo "🌐 Your API is available at:"
echo "   $APP_URL/api/v1"
echo ""
echo "🧪 Test endpoints:"
echo "   Teams:    $APP_URL/api/v1/teams"
echo "   Upcoming: $APP_URL/api/v1/upcoming"
echo ""
echo "📊 View logs:"
echo "   az webapp log tail --resource-group $RESOURCE_GROUP --name $WEB_APP_NAME"
echo ""
echo "💰 Cost: Existing App Service Plan (no additional cost)"
echo ""
echo "🔄 To update the deployment, run this script again"
echo ""
echo "⚠️  To delete web app only (preserves App Service Plan):"
echo "   az webapp delete --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP"
echo ""

# Test the deployment
echo "🧪 Testing deployment (waiting 30 seconds for app to start)..."
sleep 30

echo "Testing /api/v1/teams endpoint..."
if curl -sf "$APP_URL/api/v1/teams" > /dev/null; then
    echo "✅ API is responding!"
else
    echo "⚠️  API not responding yet. It may take a few minutes to start."
    echo "   Check logs with: az webapp log tail --resource-group $RESOURCE_GROUP --name $WEB_APP_NAME"
fi

echo ""
echo "🎉 Done!"
