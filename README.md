# Jamii Savings Bank - Integration Platform

A WSO2-based integration platform exposing three core banking APIs through WSO2 API Manager with OAuth2 security, rate limiting, and a fully automated Jenkins CI/CD pipeline.

## Project Structure

| Artifact | Location |
|----------|----------|
| MI API integrations | `src/main/wso2mi/artifacts/apis/` |
| Data service (AccountBalance) | `src/main/wso2mi/artifacts/data-services/` |
| APIM API definitions | `apis/{AccountBalanceAPI,CustomerProxyAPI,LoanEligibilityAPI}/` |
| OpenAPI specs | `apis/{API}/Definitions/swagger.yaml` |
| Database scripts | `database/init.sql`, `schema.sql`, `seed-data.sql` |
| MI Docker image | `docker/mi/Dockerfile` |
| MI deployment config | `deployment/deployment.toml` |
| Jenkins pipeline | `Jenkinsfile` |
| Pipeline scripts | `scripts/wait-for-services.sh`, `deploy-apis.sh`, `run-tests.sh` |
| Docker Compose | `docker-compose.yml` |

## Architecture Decisions and Trade-offs

**API Gateway and Integration Layer Separation:** APIM handles OAuth2 token validation, throttling, subscription management, and developer portal exposure. MI handles backend orchestration, protocol transformation, data mapping, and error normalization. Each layer has a single responsibility, meaning backend changes never touch APIM and policy changes never touch MI.

**SOAP-to-REST Transformation at the Integration Layer:** LoanEligibility accepts JSON, transforms it into a SOAP envelope inside MI, calls the calculation backend, then returns clean JSON to the client. The client has no awareness that SOAP is involved. This keeps the gateway policy-clean and makes the transformation independently testable directly against MI.

**Atomic CAR Deployment:** All three APIs are packaged into a single CAR artifact. Every deployment is atomic, either all APIs deploy or none do, enforcing version consistency across the platform.

**Docker Compose for Environment Parity:** MySQL, WSO2 MI, and WSO2 APIM run containerized using the same images that would run in production. The pipeline tears down and rebuilds the stack on every run, ensuring clean-state testing.

## Assumptions

- JSONPlaceholder and the public SOAP calculator are placeholders. In production these would be internal services behind private networks with service-account authentication and SLAs.
- Credentials are hardcoded for local development. Production would use a secrets manager such as HashiCorp Vault with credentials injected at runtime.
- A single APIM application (DefaultApplication) covers all subscriptions. In production each consumer would have its own application with separate credentials and quotas.

## What I Would Do Differently With More Time

**Webhook-driven pipeline on a dedicated server:** Currently Jenkins runs locally and is triggered manually. A GitHub webhook firing against a cloud-hosted Jenkins instance would make the pipeline fully automated and not dependent on a developer's machine being on.

**Real backend services:** JSONPlaceholder has no authentication and no SLA. In production CustomerProxy would point to the bank's actual CRM behind mutual TLS with vault-managed credentials, and LoanEligibility would call a real underwriting engine with its own compliance requirements.

**Environment promotion:** One environment currently handles everything. A proper model promotes the same CAR artifact from development through staging to production without rebuilding, with environment-specific endpoint URLs injected at deploy time.

**Observability:** MI logs would ship to ELK or Splunk with structured fields. APIM analytics would track latency and error rates per API, with alerting on defined thresholds.

## How to Run Locally

### Start Everything

```bash
git clone https://github.com/Gathuh/Jamii-Savings.git
cd Jamii-Savings

mvn clean install -DskipTests

docker compose up -d

chmod +x scripts/*.sh
./scripts/wait-for-services.sh
./scripts/deploy-apis.sh
```

### Test APIs Directly Against MI (No Token Required)

```bash
curl -s http://localhost:8290/accounts/1.0.0/ACC001/balance

curl -s http://localhost:8290/customers/1.0.0/1

curl -s -X POST http://localhost:8290/loans/1.0.0/eligibility \
  -H "Content-Type: application/json" \
  -d '{"customerId":"C123","monthlyIncome":50000,"loanAmount":20000,"loanTermMonths":12}'
```

### Test via APIM Gateway (OAuth2 Required)

Generate a token from the Developer Portal under Applications, DefaultApplication, Production Keys, then run:

```bash
curl -k https://localhost:8243/customers/1.0.0/1 \
  -H "Authorization: Bearer <your_token>"

curl -k https://localhost:8243/accounts/1.0.0/ACC001/balance \
  -H "Authorization: Bearer <your_token>"

curl -k -X POST https://localhost:8243/loans/1.0.0/eligibility \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{"customerId":"C123","monthlyIncome":50000,"loanAmount":20000,"loanTermMonths":12}'
```

### Portals

| Portal | URL | Credentials |
|--------|-----|-------------|
| Developer Portal | https://localhost:9443/devportal | admin / admin |
| Publisher | https://localhost:9443/publisher | admin / admin |

