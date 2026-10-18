# Jamii Savings Bank - Integration Platform

A WSO2-based integration platform exposing three core banking APIs through WSO2 API Manager with OAuth2 security, rate limiting, and a fully automated Jenkins CI/CD pipeline.

## Submission Contents

| Required Item | Location |
|---------------|----------|
| MI project with all three integrations | `src/main/wso2mi/artifacts/apis/` |
| DB schema and seed script | `database/init.sql`, `database/schema.sql`, `database/seed-data.sql` |
| APIM API definitions for all three | `apis/AccountBalanceAPI/`, `apis/CustomerProxyAPI/`, `apis/LoanEligibilityAPI/` |
| API Product | `apis/JamiiBankingProduct/api_product.yaml` |
| Bonus A - Dashboard Aggregation API | `src/main/wso2mi/artifacts/apis/DashboardAPI_v1.0.0.xml` |
| Jenkinsfile | `Jenkinsfile` |
| README | `README.md` |

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

**API Gateway and Integration Layer Separation:** APIM handles OAuth2 token validation, throttling, subscription management, and developer portal exposure. MI handles backend orchestration, protocol transformation, data mapping, and error normalization. Each layer has a single responsibility, meaning backend changes never touch APIM and policy changes never touch MI (see `docs/PART2_API_MANAGER.md`).

**SOAP-to-REST Transformation at the Integration Layer:** LoanEligibility accepts JSON, transforms it into a SOAP envelope inside MI, calls the calculation backend, then returns clean JSON to the client. The client has no awareness that SOAP is involved. This keeps the gateway policy-clean and makes the transformation independently testable directly against MI (see `docs/PART2_API_MANAGER.md` for the full mapping).

**Atomic CAR Deployment:** All three APIs are packaged into a single CAR artifact. Every deployment is atomic, either all APIs deploy or none do, enforcing version consistency across the platform (see `docs/PART3_PIPELINE.md`).

**Docker Compose for Environment Parity:** MySQL, WSO2 MI, and WSO2 APIM run containerized using the same images that would run in production. The pipeline tears down and rebuilds the stack on every run, ensuring clean-state testing (see `docs/PART3_PIPELINE.md`).

## Assumptions

- JSONPlaceholder and the public SOAP calculator are placeholders. In production these would be internal services behind private networks with service-account authentication and SLAs (see `docs/PART2_API_MANAGER.md` for backend choice justification).
- Credentials are hardcoded for local development. Production would use a secrets manager such as HashiCorp Vault with credentials injected at runtime.
- A single APIM application (DefaultApplication) covers all subscriptions. In production each consumer would have its own application with separate credentials and quotas (see `docs/PART2_API_MANAGER.md` for the Developer Portal subscription flow).

## What I Would Do Differently With More Time

**Webhook-driven pipeline on a dedicated server:** Currently Jenkins runs locally and is triggered manually. A GitHub webhook firing against a cloud-hosted Jenkins instance would make the pipeline fully automated and not dependent on a developer's machine being on (see `docs/PART3_PIPELINE.md` for webhook setup).

**Real backend services:** JSONPlaceholder has no authentication and no SLA. In production CustomerProxy would point to the bank's actual CRM behind mutual TLS with vault-managed credentials, and LoanEligibility would call a real underwriting engine with its own compliance requirements.

**Environment promotion:** One environment currently handles everything. A proper model promotes the same CAR artifact from development through staging to production without rebuilding, with environment-specific endpoint URLs injected at deploy time (see `docs/PART3_PIPELINE.md`).

**Observability:** MI logs would ship to ELK or Splunk with structured fields. APIM analytics would track latency and error rates per API, with alerting on defined thresholds.

## How to Run Locally

```bash
git clone https://github.com/Gathuh/Jamii-Savings.git
cd Jamii-Savings
mvn clean install -DskipTests
docker compose up -d
chmod +x scripts/*.sh
./scripts/wait-for-services.sh
./scripts/deploy-apis.sh
```

For API test commands see `docs/PART2_API_MANAGER.md`. For pipeline details see `docs/PART3_PIPELINE.md`.

| Portal | URL | Credentials |
|--------|-----|-------------|
| Developer Portal | https://localhost:9443/devportal | admin / admin |
| Publisher | https://localhost:9443/publisher | admin / admin |

For detailed technical documentation see the `docs/` folder.
