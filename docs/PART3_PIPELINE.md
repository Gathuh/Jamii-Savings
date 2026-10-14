# Part 3: Jenkins CI/CD Pipeline

## Overview

A single declarative Jenkins pipeline that builds, tests, and deploys all three Jamii Savings Bank APIs. The pipeline is defined in `Jenkinsfile` at the repository root.

## Pipeline Stages

| Stage | Description | Failure Behavior |
|-------|-------------|------------------|
| Checkout | Clone repository | Stop pipeline |
| Build MI Artifacts | `mvn clean install` creates CAR file | Stop pipeline |
| Start Infrastructure | docker compose up (MySQL, MI, APIM) | Stop pipeline |
| Deploy to MI | CAR deployed, APIs verified via health check | Stop pipeline |
| Run MI Tests | All three APIs tested against MI directly | Stop pipeline |
| Deploy APIs to APIM | All three API definitions imported | Stop pipeline |
| Deploy to Staging | Triggered on `develop` branch (placeholder) | Stop pipeline |
| Deploy to Production | Triggered on `production` branch (placeholder) | Stop pipeline |

## Environment Separation

| Environment | Trigger | Status |
|-------------|---------|--------|
| Dev | Every run | Fully wired, runs locally via Docker Compose |
| Staging | `develop` branch | Placeholder - structure exists, no live server |
| Production | `production` branch | Placeholder - structure exists, no live server |

Staging and production stages exist in the Jenkinsfile to demonstrate the promotion model. When a dedicated server is available they are activated by pointing each stage at the correct APIM and MI URLs with environment-specific credentials.

## Failure Handling

The pipeline stops immediately if any stage fails. Build failure means no deployment occurs. Infrastructure failure means no tests run. MI test failure means no APIM import happens. There is no partial deployment - all three APIs deploy together as a single CAR artifact or not at all.

## Webhook Setup (When Hosted on a Real Server)

Currently the pipeline runs on a local machine and is triggered manually. To enable webhook-driven builds when a dedicated server is available:

1. Host Jenkins on a cloud server with a public IP
2. In the GitHub repository go to Settings, Webhooks, Add webhook
3. Set Payload URL to `http://<jenkins-server>/github-webhook/`
4. Set Content type to `application/json`
5. Select "Just the push event"
6. In the Jenkins job enable "GitHub hook trigger for GITScm polling"

Every push to `main` will then trigger a full build, deploy, and test cycle automatically.

## Test Coverage

| API | Test Case | Expected |
|-----|-----------|----------|
| AccountBalanceAPI | Valid account ACC001 | 200, account data |
| AccountBalanceAPI | Invalid account | 404, error response |
| CustomerProxyAPI | Valid customer ID 1 | 200, customer data |
| LoanEligibilityAPI | Income greater than loan | 200, eligible true |
| LoanEligibilityAPI | Loan greater than income | 200, eligible false |
| LoanEligibilityAPI | Missing required fields | 400, validation error |

## Running Locally Without Jenkins

```bash
mvn clean install -DskipTests
docker compose up -d
chmod +x scripts/*.sh
./scripts/wait-for-services.sh
./scripts/run-tests.sh
./scripts/deploy-apis.sh
```
