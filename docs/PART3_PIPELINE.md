# Part 3: Jenkins CI/CD Pipeline

## Overview

A single declarative Jenkins pipeline that builds, tests, and deploys all three Jamii Savings Bank APIs.

## Pipeline Stages

| Stage | Description | Failure Behavior |
|-------|-------------|------------------|
| Checkout | Clone repository | Stop pipeline |
| Build MI Artifacts | `mvn clean install` creates CAR file | Stop pipeline |
| Start Infrastructure | docker-compose up (MySQL, MI, APIM) | Stop pipeline |
| Deploy to MI | CAR auto-deployed via volume mount | Stop pipeline |
| Run MI Tests | Test all 3 APIs against MI backend | Stop pipeline |
| Deploy APIs to APIM | apictl imports all 3 APIs | Stop pipeline |
| Deploy to Staging | Triggered on `develop` branch | Stop pipeline |
| Deploy to Production | Manual approval, `main` branch only | Stop pipeline |

## Environment Separation

| Environment | Trigger | APIM URL | Approval |
|-------------|---------|----------|----------|
| Dev | Every commit | localhost:9443 | None |
| Staging | `develop` branch | staging-apim:9443 | None |
| Production | `main` branch | prod-apim:9443 | Manual |

## Failure Handling

The pipeline uses `set -e` in all scripts and stops immediately if any step fails:

- Build failure → No deployment occurs
- Infrastructure failure → No tests run
- MI test failure → No APIM deployment
- Any APIM import failure → Pipeline fails (no partial deploy)

## Files Structure

```
├── Jenkinsfile
├── docker-compose.yml
├── database/
│   └── init.sql
├── scripts/
│   ├── wait-for-services.sh
│   ├── run-tests.sh
│   └── deploy-apis.sh
└── apis/
    ├── AccountBalanceAPI/
    ├── CustomerProxyAPI/
    └── LoanEligibilityAPI/
```

## Jenkins Requirements

- JDK 17+
- Maven 3.x
- Docker & Docker Compose
- apictl (WSO2 API Controller)
- curl

## Running Locally

```bash
mvn clean install

docker-compose up -d

./scripts/wait-for-services.sh

./scripts/run-tests.sh

./scripts/deploy-apis.sh

docker-compose down -v
```

## Test Coverage

| API | Test Case | Expected |
|-----|-----------|----------|
| AccountBalanceAPI | Valid account (ACC001) | 200, account data |
| AccountBalanceAPI | Invalid account | 404, error |
| CustomerProxyAPI | Valid customer (1) | 200, customer data |
| LoanEligibilityAPI | Eligible (income > loan) | 200, eligible: true |
| LoanEligibilityAPI | Not eligible (income < loan) | 200, eligible: false |
| LoanEligibilityAPI | Missing fields | 400, validation error |
