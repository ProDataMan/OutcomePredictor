# StatShark Documentation

Welcome to the StatShark NFL Prediction API documentation. StatShark provides AI-powered NFL game predictions using real-time data from ESPN and odds from The Odds API.

## 📁 Documentation Structure

### 📋 API Documentation (`api/`)
- **[OpenAPI Specification](api/openapi.yaml)**: Complete REST API specification with endpoints, schemas, and examples
- Interactive API documentation and testing available via Swagger UI

### 🚀 Deployment (`deployment/`)
- **[GitHub Actions Setup](deployment/GITHUB_ACTIONS_SETUP.md)**: Complete CI/CD pipeline configuration
- **[Azure Deployment Steps](deployment/AZURE_DEPLOYMENT_STEPS.md)**: Manual Azure deployment guide
- **[Deployment Script](deployment/deploy-to-azure.sh)**: Automated deployment script

### 📚 User Guides (`guides/`)
- **[Quick Start - Server](guides/QUICK_START_SERVER.md)**: Get the API server running locally
- **[Quick Start - iOS](guides/QUICK_START_iOS.md)**: Build and run the iOS app
- **[Running Guide](guides/RUNNING.md)**: Comprehensive setup and running instructions
- **[Testing Guide](guides/TESTING.md)**: How to test the application

## 🏗️ Architecture Overview

StatShark consists of several components:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   iOS App       │    │   Server API    │    │  Data Sources   │
│  (SwiftUI)      │◄──►│   (Vapor)       │◄──►│ ESPN + Odds API │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │  AI Prediction  │
                       │    Engine       │
                       └─────────────────┘
```

### Core Components

1. **OutcomePredictor**: Core prediction engine and data models
2. **OutcomePredictorAPI**: API DTOs and mappers
3. **NFLServer**: Vapor-based REST API server with OpenAPI support
4. **NFLPredictorApp**: SwiftUI iOS application
5. **NFLPredictCLI**: Command-line interface for predictions

## 🚀 Quick Start

### Prerequisites
- Swift 6.2+
- Docker (for deployment)
- Odds API key from [The Odds API](https://the-odds-api.com)

### Local Development

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ProDataMan/OutcomePredictor.git
   cd OutcomePredictor
   ```

2. **Set environment variables**:
   ```bash
   export ODDS_API_KEY="your_api_key_here"
   ```

3. **Build and run the server**:
   ```bash
   swift run nfl-server serve --hostname 0.0.0.0 --port 8080
   ```

4. **Test the API**:
   ```bash
   curl http://localhost:8080/api/v1/teams
   ```

### Production Deployment

StatShark uses automated GitHub Actions deployment to Azure App Service. See the [deployment documentation](deployment/) for complete setup instructions.

## 🔑 API Authentication

The current version uses API key authentication for external data sources (ESPN, Odds API). No authentication is required for client requests to the StatShark API.

## 📊 API Endpoints

### Core Endpoints

| Endpoint | Method | Description |
|----------|---------|------------|
| `/api/v1/teams` | GET | List all NFL teams |
| `/api/v1/teams/{id}` | GET | Get team details |
| `/api/v1/upcoming` | GET | Upcoming games with predictions |
| `/api/v1/current-week` | GET | Current week games and scores |
| `/api/v1/predict/{home}/{away}` | GET | Generate prediction for specific matchup |

### Response Format

All API responses follow a consistent JSON structure:

```json
{
  "data": [...],
  "meta": {
    "lastUpdated": "2024-12-15T19:30:00Z"
  }
}
```

## 🧠 Prediction Models

StatShark uses multiple prediction strategies:

1. **Baseline Predictor**: Statistical analysis based on team performance
2. **LLM Predictor**: AI-powered analysis using language models
3. **Ensemble**: Combines multiple prediction methods

### Confidence Scoring

Predictions include confidence scores (0-1) indicating model certainty:
- **0.9-1.0**: Very high confidence
- **0.7-0.9**: High confidence
- **0.5-0.7**: Moderate confidence
- **0.0-0.5**: Low confidence

## 🔄 Data Sources

### ESPN API
- Real-time scores and game data
- Team statistics and schedules
- No authentication required

### The Odds API
- Live betting odds and lines
- Requires API key subscription
- Updates every 10 minutes

## 📱 iOS Application

The StatShark iOS app provides:
- Live game scores and predictions
- Team details and statistics
- User-friendly prediction interface
- Real-time data updates

See the [iOS Quick Start Guide](guides/QUICK_START_iOS.md) for setup instructions.

## 🛠️ Development

### Testing
```bash
# Run all tests
swift test --no-parallel

# Run specific test
swift test --filter TestName --no-parallel
```

### Adding New Features

1. Update OpenAPI specification in `Sources/NFLServer/openapi.yaml`
2. Regenerate types: `swift build`
3. Implement new endpoints in server code
4. Add corresponding iOS app features
5. Update documentation

## 🚀 Deployment

### GitHub Actions CI/CD

Every push to `main` triggers:
1. ✅ Swift build and test
2. ✅ Docker image build
3. ✅ Deploy to Azure App Service
4. ✅ Run integration tests

### Manual Deployment

Use the provided deployment script:
```bash
./docs/deployment/deploy-to-azure.sh
```

## 📞 Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/ProDataMan/OutcomePredictor/issues)
- **API Status**: Monitor at production URL
- **Documentation**: This docs folder

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.

---

**StatShark** - AI-Powered NFL Predictions 🦈🏈