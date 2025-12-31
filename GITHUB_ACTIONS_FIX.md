# GitHub Actions Deployment Fix

## Issue
GitHub Actions workflow is failing during Azure deployment. Local builds and tests pass successfully, but deployment to Azure fails.

## Root Cause
The build/test stage completes successfully. The failure occurs in the `deploy-to-azure` job, likely due to one of:

1. **Expired Azure Credentials** - `AZURE_CREDENTIALS` secret may be expired
2. **Expired Registry Password** - `AZURE_REGISTRY_PASSWORD` secret may be expired
3. **Missing API Keys** - `ODDS_API_KEY` or `API_SPORTS_KEY` secrets may be missing/invalid
4. **Azure Resource Issues** - Container Registry or Web App may have configuration problems

## Verification Steps

### 1. Check Local Build (Already Verified ✅)
```bash
swift build --configuration release --product nfl-server
swift test --no-parallel --configuration release
```
Both complete successfully with all 19 tests passing.

### 2. Verify GitHub Secrets

Navigate to: `https://github.com/ProDataMan/OutcomePredictor/settings/secrets/actions`

Required secrets:
- `AZURE_CREDENTIALS` - Azure service principal credentials (JSON format)
- `AZURE_REGISTRY_PASSWORD` - Azure Container Registry access password
- `ODDS_API_KEY` - API key for odds data (optional for build, required for runtime)
- `API_SPORTS_KEY` - API key for sports data (optional for build, required for runtime)

### 3. Renew Azure Credentials

If credentials are expired, create new service principal:

```bash
# Login to Azure
az login

# Create service principal with contributor role
az ad sp create-for-rbac \
  --name "statshark-github-actions" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/ProDataMan \
  --sdk-auth
```

Copy the JSON output and update the `AZURE_CREDENTIALS` secret in GitHub.

### 4. Get Azure Container Registry Password

```bash
# Get registry credentials
az acr credential show --name statsharkregistry --resource-group statshark-rg
```

Update `AZURE_REGISTRY_PASSWORD` secret with the password value.

### 5. Test Azure Connection Locally

```bash
# Test Azure login
az login

# Test container registry access
az acr login --name statsharkregistry

# Check web app status
az webapp show \
  --resource-group ProDataMan \
  --name statshark-api
```

### 6. Review Deployment Logs

To see detailed error messages:

```bash
# Download recent logs
az webapp log download \
  --resource-group ProDataMan \
  --name statshark-api \
  --log-file deployment-logs.zip

# Or tail live logs
az webapp log tail \
  --resource-group ProDataMan \
  --name statshark-api
```

## Recommended Fix Workflow

1. **Verify secrets are current** - Check GitHub repository secrets
2. **Renew Azure credentials** - Create new service principal if needed
3. **Update GitHub secrets** - Add new credentials to repository
4. **Trigger manual deployment** - Use workflow_dispatch to test
5. **Monitor deployment** - Watch Azure logs for issues

## Manual Deployment Test

You can manually trigger the workflow:
1. Go to Actions tab in GitHub
2. Select "🦈 Deploy StatShark to Azure" workflow
3. Click "Run workflow"
4. Select branch: `main`
5. Click "Run workflow" button

This allows testing without pushing new code.

## Alternative: Deploy from Local Machine

If GitHub Actions continues to fail, deploy directly:

```bash
# Build Docker image locally
docker build -t statsharkregistry.azurecr.io/statshark-server:latest .

# Login to Azure Container Registry
az acr login --name statsharkregistry

# Push image
docker push statsharkregistry.azurecr.io/statshark-server:latest

# Update web app
az webapp config container set \
  --name statshark-api \
  --resource-group ProDataMan \
  --docker-custom-image-name statsharkregistry.azurecr.io/statshark-server:latest

# Restart app
az webapp restart \
  --resource-group ProDataMan \
  --name statshark-api
```

## Prevention

To prevent future credential expiration issues:

1. **Set calendar reminders** - Azure credentials typically expire after 1 year
2. **Monitor workflow** - Check Actions tab regularly for failures
3. **Automate credential rotation** - Use Azure Key Vault with managed identities (advanced)

## Environment Variables

The deployment configures these environment variables on Azure:

- `ENV=production`
- `PORT=8080`
- `WEBSITES_PORT=8080`
- `ESPN_BASE_URL=https://site.api.espn.com/apis/site/v2/sports/football/nfl`
- `ODDS_API_BASE_URL=https://api.the-odds-api.com/v4`
- `SERVER_BASE_URL=https://statshark-api.azurewebsites.net/api/v1`
- `CACHE_EXPIRATION=21600`
- `ODDS_API_KEY` (from secret)
- `API_SPORTS_KEY` (from secret)

Verify these match expected values in Azure Portal.

## Support Resources

- [Azure Service Principal Docs](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [GitHub Actions Azure Login](https://github.com/Azure/login)
- [Azure Container Registry Authentication](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication)
