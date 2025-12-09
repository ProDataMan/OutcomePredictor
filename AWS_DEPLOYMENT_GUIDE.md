# AWS Deployment Guide for NFL Prediction Server

## Network Access Setup

AWS endpoints are blocked by default. To deploy to AWS:

### 1. Unblock AWS Domains

Open monitoring dashboard: http://localhost:4073

Add these domains:
- `aws.amazon.com`
- `*.amazonaws.com`
- `ecr.us-east-1.amazonaws.com` (or your preferred region)
- `s3.amazonaws.com`
- `elasticbeanstalk.us-east-1.amazonaws.com`

Set each as **Permanent** for consistent access.

## Prerequisites

### Install AWS CLI

```bash
brew install awscli
```

### Configure AWS Credentials

```bash
aws configure
```

Enter:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-east-1`
- Default output format: `json`

## Deployment Option 1: AWS Elastic Beanstalk (Simplest)

### Step 1: Install EB CLI

```bash
brew install awsebcli
```

### Step 2: Initialize Elastic Beanstalk

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor

# Initialize EB application
eb init -p docker nfl-predictor \
  --region us-east-1
```

### Step 3: Create Dockerrun.aws.json

Create deployment configuration:

```bash
cat > Dockerrun.aws.json << 'EOF'
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "nfl-server:latest",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": 8080,
      "HostPort": 8080
    }
  ],
  "Environment": [
    {
      "Name": "ENV",
      "Value": "production"
    },
    {
      "Name": "PORT",
      "Value": "8080"
    },
    {
      "Name": "ESPN_BASE_URL",
      "Value": "https://site.api.espn.com/apis/site/v2/sports/football/nfl"
    },
    {
      "Name": "ODDS_API_BASE_URL",
      "Value": "https://api.the-odds-api.com/v4"
    },
    {
      "Name": "CACHE_EXPIRATION",
      "Value": "21600"
    }
  ]
}
EOF
```

### Step 4: Create Environment

```bash
# Create environment with Docker
eb create nfl-predictor-env \
  --instance-type t3.small \
  --single
```

### Step 5: Set Environment Variables

```bash
# Set your Odds API key
eb setenv ODDS_API_KEY=your_odds_api_key_here

# Get the environment URL
eb status
```

### Step 6: Deploy Application

```bash
# Deploy current version
eb deploy

# Open in browser to test
eb open
```

Your API is available at: `http://<env-name>.us-east-1.elasticbeanstalk.com/api/v1`

## Deployment Option 2: AWS ECS (Container Service)

### Step 1: Create ECR Repository

```bash
# Create container registry
aws ecr create-repository \
  --repository-name nfl-predictor \
  --region us-east-1
```

### Step 2: Build and Push Docker Image

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor

# Get ECR login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <your-account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build image
docker build -t nfl-predictor .

# Tag image
docker tag nfl-predictor:latest \
  <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/nfl-predictor:latest

# Push to ECR
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/nfl-predictor:latest
```

### Step 3: Create ECS Cluster

```bash
aws ecs create-cluster \
  --cluster-name nfl-predictor-cluster \
  --region us-east-1
```

### Step 4: Create Task Definition

Create `task-definition.json`:

```json
{
  "family": "nfl-predictor",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "nfl-server",
      "image": "<your-account-id>.dkr.ecr.us-east-1.amazonaws.com/nfl-predictor:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENV",
          "value": "production"
        },
        {
          "name": "PORT",
          "value": "8080"
        },
        {
          "name": "ODDS_API_KEY",
          "value": "your_odds_api_key_here"
        },
        {
          "name": "ESPN_BASE_URL",
          "value": "https://site.api.espn.com/apis/site/v2/sports/football/nfl"
        },
        {
          "name": "ODDS_API_BASE_URL",
          "value": "https://api.the-odds-api.com/v4"
        },
        {
          "name": "CACHE_EXPIRATION",
          "value": "21600"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/nfl-predictor",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

Register task:

```bash
aws ecs register-task-definition \
  --cli-input-json file://task-definition.json
```

### Step 5: Create Service

```bash
# Create security group (if needed)
aws ec2 create-security-group \
  --group-name nfl-predictor-sg \
  --description "NFL Predictor Security Group" \
  --vpc-id <your-vpc-id>

# Allow inbound traffic on port 8080
aws ec2 authorize-security-group-ingress \
  --group-id <security-group-id> \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0

# Create ECS service
aws ecs create-service \
  --cluster nfl-predictor-cluster \
  --service-name nfl-predictor-service \
  --task-definition nfl-predictor \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<subnet-id>],securityGroups=[<security-group-id>],assignPublicIp=ENABLED}"
```

## Deployment Option 3: AWS Lambda + API Gateway

For serverless deployment with automatic scaling.

### Step 1: Create Lambda Handler

Create `lambda-handler.sh`:

```bash
#!/bin/bash
# Lambda custom runtime for Swift Vapor

set -euo pipefail

# Start Vapor server
exec /var/task/nfl-server serve \
  --hostname 0.0.0.0 \
  --port 8080
```

### Step 2: Package for Lambda

```bash
# Build release
swift build -c release

# Create deployment package
mkdir -p lambda-deploy
cp .build/release/nfl-server lambda-deploy/
cp lambda-handler.sh lambda-deploy/bootstrap
chmod +x lambda-deploy/bootstrap

cd lambda-deploy
zip -r ../nfl-lambda.zip .
cd ..
```

### Step 3: Create Lambda Function

```bash
aws lambda create-function \
  --function-name nfl-predictor \
  --runtime provided.al2 \
  --role arn:aws:iam::<account-id>:role/lambda-execution-role \
  --handler bootstrap \
  --zip-file fileb://nfl-lambda.zip \
  --timeout 30 \
  --memory-size 512 \
  --environment Variables="{
    ENV=production,
    PORT=8080,
    ODDS_API_KEY=your_key_here,
    ESPN_BASE_URL=https://site.api.espn.com/apis/site/v2/sports/football/nfl,
    ODDS_API_BASE_URL=https://api.the-odds-api.com/v4,
    CACHE_EXPIRATION=21600
  }"
```

### Step 4: Create API Gateway

```bash
# Create REST API
aws apigateway create-rest-api \
  --name nfl-predictor-api \
  --description "NFL Prediction API"

# Configure routes and integration
# (Full API Gateway setup requires multiple steps - see AWS docs)
```

## Cost Estimates

### Elastic Beanstalk (t3.small)
- **Instance**: ~$15/month
- **Load Balancer**: ~$18/month (if used)
- **Total**: ~$15-33/month

### ECS Fargate
- **Compute**: ~$15/month (0.5 vCPU, 1GB RAM, always on)
- **Data Transfer**: ~$1-5/month
- **Total**: ~$16-20/month

### Lambda + API Gateway
- **Lambda**: Free tier (1M requests/month), then $0.20/1M requests
- **API Gateway**: Free tier (1M calls/month), then $3.50/1M calls
- **Total**: ~$0-10/month (scales with usage)

**Recommendation**: Use **Elastic Beanstalk** for simplicity or **ECS Fargate** for better control.

## Update iOS App for AWS

After deployment, update the production URL in `APIClient.swift`:

```swift
#else
// Production: AWS server
self.baseURL = baseURL ?? "http://<your-env>.us-east-1.elasticbeanstalk.com/api/v1"
#endif
```

Or for ECS with load balancer:
```swift
self.baseURL = baseURL ?? "http://<load-balancer-dns>/api/v1"
```

## Monitoring

### Elastic Beanstalk

```bash
# View logs
eb logs

# Check health
eb health

# SSH into instance (for debugging)
eb ssh
```

### ECS

```bash
# View running tasks
aws ecs list-tasks --cluster nfl-predictor-cluster

# View logs
aws logs tail /ecs/nfl-predictor --follow
```

## SSL/HTTPS Setup

### Option 1: AWS Certificate Manager (Free)

```bash
# Request certificate
aws acm request-certificate \
  --domain-name api.yourdomain.com \
  --validation-method DNS

# Configure load balancer to use certificate
```

### Option 2: Use CloudFront

CloudFront provides free SSL with AWS-provided certificates.

## Cleanup

### Elastic Beanstalk
```bash
eb terminate nfl-predictor-env
```

### ECS
```bash
aws ecs delete-service \
  --cluster nfl-predictor-cluster \
  --service nfl-predictor-service \
  --force

aws ecs delete-cluster \
  --cluster nfl-predictor-cluster
```

## Troubleshooting

### Container Won't Start

Check logs:
```bash
# EB
eb logs

# ECS
aws logs tail /ecs/nfl-predictor --follow
```

### Connection Timeout

Verify security group allows inbound on port 8080:
```bash
aws ec2 describe-security-groups \
  --group-ids <security-group-id>
```

### Environment Variables Not Set

Check configuration:
```bash
# EB
eb printenv

# ECS
aws ecs describe-task-definition \
  --task-definition nfl-predictor
```

## Next Steps

1. Unblock AWS domains at http://localhost:4073
2. Install AWS CLI: `brew install awscli`
3. Configure credentials: `aws configure`
4. Choose deployment option (Elastic Beanstalk recommended)
5. Follow deployment steps
6. Update iOS app with production URL
7. Test API endpoint
8. Proceed with App Store submission
