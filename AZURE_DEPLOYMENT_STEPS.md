# Azure Deployment Steps - Manual Guide

## Network Access Required

Azure deployment is currently blocked by Apple network proxy restrictions. To deploy:

1. Go to Apple Claude Code dashboard
2. Unblock network access to `*.azure.com` and `*.microsoftonline.com`
3. Run these commands after unblocking

## Step 1: Create Resource Group

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
az group create --name nfl-predictor-rg --location eastus
```

## Step 2: Create Container Registry

```bash
az acr create \
  --resource-group nfl-predictor-rg \
  --name nflpredictorregistry \
  --sku Basic
```

## Step 3: Build Docker Image

```bash
# Build the Docker image
docker build -t nflpredictorregistry.azurecr.io/nfl-server:latest .

# Test locally first (optional)
docker run -p 8080:8080 \
  -e ODDS_API_KEY=$ODDS_API_KEY \
  nflpredictorregistry.azurecr.io/nfl-server:latest
```

## Step 4: Push to Azure Container Registry

```bash
# Login to registry
az acr login --name nflpredictorregistry

# Push image
docker push nflpredictorregistry.azurecr.io/nfl-server:latest
```

## Step 5: Create App Service Plan

```bash
az appservice plan create \
  --name nfl-predictor-plan \
  --resource-group nfl-predictor-rg \
  --sku B1 \
  --is-linux
```

## Step 6: Create Web App

```bash
az webapp create \
  --resource-group nfl-predictor-rg \
  --plan nfl-predictor-plan \
  --name nfl-predictor-api \
  --deployment-container-image-name nflpredictorregistry.azurecr.io/nfl-server:latest
```

## Step 7: Configure Container Registry Credentials

```bash
# Get registry password
REGISTRY_PASSWORD=$(az acr credential show \
  --name nflpredictorregistry \
  --query "passwords[0].value" -o tsv)

# Configure web app
az webapp config container set \
  --name nfl-predictor-api \
  --resource-group nfl-predictor-rg \
  --docker-custom-image-name nflpredictorregistry.azurecr.io/nfl-server:latest \
  --docker-registry-server-url https://nflpredictorregistry.azurecr.io \
  --docker-registry-server-user nflpredictorregistry \
  --docker-registry-server-password $REGISTRY_PASSWORD
```

## Step 8: Configure Environment Variables

**IMPORTANT**: Replace `your_odds_api_key_here` with your actual Odds API key.

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

## Step 9: Enable HTTPS

```bash
az webapp update \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api \
  --https-only true
```

## Step 10: Verify Deployment

```bash
# Check app status
az webapp show \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api \
  --query state

# Test API endpoint
curl https://nfl-predictor-api.azurewebsites.net/api/v1/teams
```

## Your Production API URL

After deployment, your API is available at:

```
https://nfl-predictor-api.azurewebsites.net/api/v1
```

## Monitoring and Logs

### View Live Logs

```bash
az webapp log tail \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api
```

### View Log Stream in Browser

```bash
az webapp browse \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api
```

## Cost Estimates

- **App Service B1 Plan**: ~$13/month
- **Container Registry Basic**: ~$5/month
- **Total**: ~$18/month

## Cleanup (When Needed)

To delete all Azure resources:

```bash
az group delete --name nfl-predictor-rg --yes
```

## Troubleshooting

### Container Not Starting

Check logs:
```bash
az webapp log tail --resource-group nfl-predictor-rg --name nfl-predictor-api
```

### Connection Timeout

Restart the app:
```bash
az webapp restart --resource-group nfl-predictor-rg --name nfl-predictor-api
```

### Update Environment Variables

```bash
az webapp config appsettings set \
  --resource-group nfl-predictor-rg \
  --name nfl-predictor-api \
  --settings KEY=VALUE
```
