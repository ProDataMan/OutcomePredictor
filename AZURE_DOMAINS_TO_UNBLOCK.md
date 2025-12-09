# Azure Deployment - Domain Unblock Guide

## Required Domains to Unblock

Open the monitoring dashboard at: **http://localhost:4073**

Add these specific domains (no wildcards needed):

### Core Azure Domains
1. `management.azure.com` - Azure Resource Manager API
2. `login.microsoftonline.com` - Azure authentication
3. `graph.windows.net` - Azure Active Directory Graph API

### Container Registry Domains
4. `statsharkregistry.azurecr.io` - StatShark container registry (will be created)
5. `azurecr.io` - Azure Container Registry base domain

### App Service Domains
6. `statshark-api.azurewebsites.net` - StatShark web app (will be created)
7. `azurewebsites.net` - Azure App Service base domain

### Additional Azure Services
8. `azure.com` - Main Azure portal
9. `aadcdn.msftauth.net` - Azure AD authentication CDN
10. `windows.net` - Legacy Azure domain (still used by some services)

## Steps to Unblock

For each domain above:

1. Open http://localhost:4073
2. Click "Domains" in the sidebar
3. Click "Add Domain" button
4. Enter the domain name (exactly as listed above)
5. Select **"Permanent"** for the duration
6. Click "Add Domain"
7. Repeat for all 10 domains

## After Unblocking

Once all domains are unblocked, run the deployment script:

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
chmod +x deploy-to-azure.sh
./deploy-to-azure.sh
```

The script will prompt for your Odds API key if not set in environment.

## Verification

After adding domains, verify they're accessible:

```bash
# Test Azure login
curl -I https://login.microsoftonline.com

# Should return HTTP 200 or 3xx (not 403)
```

## Troubleshooting

If deployment still fails with 403 errors, check the error message for the specific domain being blocked and add it to the dashboard.

Common additional domains that might be needed:
- `microsoftonline-p.com`
- `azure-api.net`
- `core.windows.net` (for storage accounts)
