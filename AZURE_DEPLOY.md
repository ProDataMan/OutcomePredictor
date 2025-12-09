# Azure Deployment Guide for NFL Prediction Server

This guide walks through deploying the NFL prediction server to Azure App Service using your MCT Azure credits.

## Prerequisites

- Azure CLI installed: `brew install azure-cli`
- Docker installed (for container deployment)
- Azure subscription with credits

## Option 1: Azure Container Instance (Simplest)

### Step 1: Login to Azure

```bash
az login
```

### Step 2: Create Resource Group

```bash
az group create --name nfl-predictor-rg --location eastus
```

### Step 3: Create Container Registry

```bash
az acr create \
  --resource-group nfl-predictor-rg \
  --name nflpredictorregistry \
  --sku Basic
```

### Step 4: Build and Push Docker Image

```bash
# Login to registry
az acr login --name nflpredictorregistry

# Build image
docker build -t nflpredictorregistry.azurecr.io/nfl-server:latest .

# Push image
docker push nflpredictorregistry.azurecr.io/nfl-server:latest
```

### Step 5: Deploy to Azure Container Instance

```bash
az container create \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api \
  --image nflpredictorregistry.azurecr.io/nfl-server:latest \
  --cpu 1 \
  --memory 1 \
  --registry-login-server nflpredictorregistry.azurecr.io \
  --registry-username nflpredictorregistry \
  --registry-password $(az acr credential show --name nflpredictorregistry --query "passwords[0].value" -o tsv) \
  --dns-name-label nfl-predictor-api \
  --ports 8080 \
  --environment-variables \
    ENV=production \
    PORT=8080 \
    ODDS_API_KEY=your_odds_api_key_here \
    ESPN_BASE_URL=https://site.api.espn.com/apis/site/v2/sports/football/nfl \
    ODDS_API_BASE_URL=https://api.the-odds-api.com/v4 \
    CACHE_EXPIRATION=21600
```

### Step 6: Get URL

```bash
az container show \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api \
  --query ipAddress.fqdn \
  --output tsv
```

Your API is now available at: `http://<fqdn>:8080/api/v1`

## Option 2: Azure App Service (More Features)

### Step 1: Create App Service Plan

```bash
az appservice plan create \
  --name nfl-predictor-plan \
  --resource-group nfl-predictor-rg \
  --sku B1 \
  --is-linux
```

### Step 2: Create Web App

```bash
az webapp create \
  --resource-group nfl-predictor-rg \
  --plan nfl-predictor-plan \
  --name nfl-predictor-api \
  --deployment-container-image-name nflpredictorregistry.azurecr.io/nfl-server:latest
```

### Step 3: Configure Container Registry

```bash
az webapp config container set \
  --name nfl-predictor-api \
  --resource-group nfl-predictor-rg \
  --docker-custom-image-name nflpredictorregistry.azurecr.io/nfl-server:latest \
  --docker-registry-server-url https://nflpredictorregistry.azurecr.io \
  --docker-registry-server-user nflpredictorregistry \
  --docker-registry-server-password $(az acr credential show --name nflpredictorregistry --query "passwords[0].value" -o tsv)
```

### Step 4: Configure Environment Variables

```bash
az webapp config appsettings set \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api \
  --settings \
    ENV=production \
    PORT=8080 \
    ODDS_API_KEY=your_odds_api_key_here \
    ESPN_BASE_URL=https://site.api.espn.com/apis/site/v2/sports/football/nfl \
    ODDS_API_BASE_URL=https://api.the-odds-api.com/v4 \
    SERVER_BASE_URL=https://nfl-predictor-api.azurewebsites.net/api/v1 \
    CACHE_EXPIRATION=21600
```

### Step 5: Enable HTTPS

```bash
az webapp update \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api \
  --https-only true
```

Your API is now available at: `https://nfl-predictor-api.azurewebsites.net/api/v1`

## Update iOS App

After deployment, update your iOS app to use the production URL.

Set environment variable before building for production:

```bash
export SERVER_BASE_URL=https://nfl-predictor-api.azurewebsites.net/api/v1
```

Or configure in Xcode scheme:
1. Edit Scheme > Run > Arguments
2. Add Environment Variable: `SERVER_BASE_URL` = `https://nfl-predictor-api.azurewebsites.net/api/v1`

## Monitoring

### View Logs

```bash
az webapp log tail \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api
```

### Check Container Status

```bash
az container show \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api \
  --query instanceView.state
```

## Cost Management

Azure Container Instance pricing:
- 1 vCPU, 1GB RAM: ~$0.0000125 per second (~$1/day)
- Stop when not in use: `az container stop --resource-group nfl-predictor-rg --name nfl-predictor-api`

Azure App Service B1 tier:
- ~$13/month
- Always-on, better for production
- Auto-scaling available

## Cleanup

To delete all resources:

```bash
az group delete --name nfl-predictor-rg --yes
```
