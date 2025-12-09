# GitHub Actions CI/CD Setup

This project uses GitHub Actions for automated testing and deployment to Azure App Service.

## Workflows Overview

### 🚀 `deploy.yml` - Main Deployment Pipeline
- **Triggers**: Push to `master` or `main` branch, manual trigger
- **Jobs**:
  1. **Build & Test**: Compiles Swift code and runs test suite
  2. **Deploy to Azure**: Builds Docker image and deploys to Azure App Service
  3. **Notify**: Provides deployment summary

### 🧪 `test.yml` - Pull Request Validation
- **Triggers**: Pull requests to `master` or `main` branch
- **Jobs**:
  1. **Run Tests**: Validates code changes don't break functionality
  2. **Validate Docker**: Ensures Docker image builds successfully

## Required GitHub Secrets

You must configure these secrets in your GitHub repository settings:

### 1. Azure Authentication
Navigate to **Settings** → **Secrets and variables** → **Actions** and add:

#### `AZURE_CREDENTIALS`
Azure service principal credentials for authentication:

```json
{
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret",
  "subscriptionId": "9cdd24b5-1454-4481-bbf4-1d8f358dd990",
  "tenantId": "0c7b7c9c-4262-417d-b9d7-211b36ce0ce4"
}
```

To create Azure service principal:
```bash
az ad sp create-for-rbac \
  --name "github-actions-statshark" \
  --role contributor \
  --scopes /subscriptions/9cdd24b5-1454-4481-bbf4-1d8f358dd990/resourceGroups/ProDataMan \
  --sdk-auth
```

#### `AZURE_REGISTRY_PASSWORD`
Azure Container Registry password:

```bash
az acr credential show --name statsharkregistry --query "passwords[0].value" -o tsv
```

#### `ODDS_API_KEY`
Your API key from the-odds-api.com:
```
329088a703ba82a2103e7e7c6508500f
```

## Deployment Configuration

The workflow uses these Azure resources (already configured):

- **Resource Group**: `ProDataMan`
- **Container Registry**: `statsharkregistry` (in `statshark-rg`)
- **App Service Plan**: `ASP-ProDataMan-996c`
- **Web App**: `statshark-api`

## Environment Variables

The deployment automatically configures these environment variables:

| Variable | Value |
|----------|--------|
| `ENV` | `production` |
| `PORT` | `8080` |
| `WEBSITES_PORT` | `8080` |
| `ODDS_API_KEY` | From GitHub secret |
| `ESPN_BASE_URL` | `https://site.api.espn.com/apis/site/v2/sports/football/nfl` |
| `ODDS_API_BASE_URL` | `https://api.the-odds-api.com/v4` |
| `SERVER_BASE_URL` | `https://statshark-api.azurewebsites.net/api/v1` |
| `CACHE_EXPIRATION` | `21600` |

## Manual Deployment Trigger

You can manually trigger a deployment:

1. Go to **Actions** tab in your repository
2. Select **Deploy StatShark to Azure** workflow
3. Click **Run workflow**
4. Choose the branch (typically `main`)
5. Click **Run workflow**

## Monitoring Deployments

### GitHub Actions Dashboard
- View build/deploy progress in the **Actions** tab
- Each workflow run shows detailed logs and status
- Deployment summary appears at the end of successful runs

### Azure Monitoring
After deployment, monitor your app:

```bash
# View live logs
az webapp log tail --resource-group ProDataMan --name statshark-api

# Check app status
az webapp show --resource-group ProDataMan --name statshark-api --query state
```

### Test Endpoints
After successful deployment, test these endpoints:

- **API Base**: https://statshark-api.azurewebsites.net/api/v1
- **Teams**: https://statshark-api.azurewebsites.net/api/v1/teams
- **Upcoming Games**: https://statshark-api.azurewebsites.net/api/v1/upcoming

## Troubleshooting

### Common Issues

**Build Failures**
- Check Swift version compatibility (using 6.2)
- Ensure all tests pass locally: `swift test --no-parallel`

**Deployment Failures**
- Verify Azure credentials in secrets
- Check Azure resource names match workflow configuration
- Review Azure App Service logs

**API Not Responding**
- Check environment variables are set correctly
- Verify container started successfully: `az webapp log tail`
- Restart if needed: `az webapp restart --resource-group ProDataMan --name statshark-api`

### Debug Commands

```bash
# Download deployment logs
az webapp log download --resource-group ProDataMan --name statshark-api --log-file logs.zip

# Check container settings
az webapp config container show --resource-group ProDataMan --name statshark-api

# View app settings
az webapp config appsettings list --resource-group ProDataMan --name statshark-api
```

## Security Best Practices

- ✅ Secrets stored in GitHub encrypted secrets
- ✅ Azure resources use managed identities where possible
- ✅ HTTPS-only deployment enforced
- ✅ Container registry uses secure authentication
- ✅ Production environment isolation

## Cost Monitoring

Estimated monthly costs:
- **App Service B1 Plan**: Already allocated
- **Container Registry**: ~$5/month
- **Data Transfer**: Minimal
- **Total Additional**: ~$5/month