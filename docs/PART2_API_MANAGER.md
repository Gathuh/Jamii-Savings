# Part 2: API Manager Integration

## Overview

This document describes how the three Jamii Savings Bank integration APIs are exposed through WSO2 API Manager with security, throttling, and gateway policies.

## Published APIs

| API Name | Context | Version | Throttling Tier | Security |
|----------|---------|---------|-----------------|----------|
| AccountBalanceAPI | /accounts | 1.0.0 | Unlimited | OAuth2 |
| CustomerProxyAPI | /customers | 1.0.0 | Unlimited | OAuth2 |
| LoanEligibilityAPI | /loans | 1.0.0 | **Gold** | OAuth2 |

### Throttling Tier Rationale

**LoanEligibilityAPI uses Gold tier** (1000 requests/min) instead of Unlimited because:
- Loan eligibility checks involve backend SOAP service calls with external dependencies
- Rate limiting prevents abuse and protects the downstream calculator service
- Financial decision APIs should have controlled access to ensure fair usage

## Security Scheme

All APIs use **OAuth2** with client credentials flow:

```bash
# Get access token
curl -k -X POST https://localhost:9443/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "<ConsumerKey>:<ConsumerSecret>" \
  -d "grant_type=client_credentials"

# Call API with token
curl -k https://localhost:8243/accounts/1.0.0/ACC001/balance \
  -H "Authorization: Bearer <access_token>"
```

## Custom Gateway Mediation Policy

**AccountBalanceAPI** has a custom gateway policy that injects bank identification headers:

```xml
<header name="X-Bank-Name" value="JamiiSavings" scope="transport"/>
<header name="X-Bank-Country" value="Kenya" scope="transport"/>
<header name="X-API-Version" value="1.0.0" scope="transport"/>
```

**Purpose:** Downstream systems can identify the source bank and API version for audit trails and routing decisions.

## API Product

**JamiiBankingProduct** bundles all three APIs under a single subscription:

- Context: `/jamii-banking`
- Version: 1.0.0
- Included APIs: AccountBalanceAPI, CustomerProxyAPI, LoanEligibilityAPI

**Benefits:**
- Single subscription for complete banking functionality
- Simplified developer onboarding
- Consistent billing and usage tracking

## Developer Portal Subscription Guide

### How to Discover and Subscribe to APIs

1. **Access Developer Portal**
   - URL: https://localhost:9443/devportal
   - Login with your developer credentials (or register)

2. **Browse APIs**
   - Click "APIs" in the top menu
   - Search for "Jamii" or browse by category
   - View API documentation, try out endpoints

3. **Create an Application**
   - Go to "Applications" → "Add New Application"
   - Name: e.g., "MyBankingApp"
   - Select throttling policy (Unlimited, Gold, Silver, Bronze)
   - Click "Save"

4. **Subscribe to APIs**
   - Go to an API (e.g., AccountBalanceAPI)
   - Click "Subscribe"
   - Select your application
   - Choose subscription tier
   - Click "Subscribe"
   
   *Or subscribe to JamiiBankingProduct for all 3 APIs at once*

5. **Generate Credentials**
   - Go to "Applications" → Your App → "Production Keys"
   - Click "Generate Keys"
   - Copy Consumer Key and Consumer Secret

6. **Get Access Token**
   ```bash
   curl -k -X POST https://localhost:9443/oauth2/token \
     -u "<ConsumerKey>:<ConsumerSecret>" \
     -d "grant_type=client_credentials"
   ```

7. **Call APIs**
   ```bash
   # Account Balance
   curl -k https://localhost:8243/accounts/1.0.0/ACC001/balance \
     -H "Authorization: Bearer <token>"
   
   # Customer Profile
   curl -k https://localhost:8243/customers/1.0.0/1 \
     -H "Authorization: Bearer <token>"
   
   # Loan Eligibility
   curl -k -X POST https://localhost:8243/loans/1.0.0/eligibility \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{"customerId":"C123","monthlyIncome":50000,"loanAmount":20000}'
   ```

## Gateway URLs

| Environment | HTTP | HTTPS |
|-------------|------|-------|
| Gateway | http://localhost:8280 | https://localhost:8243 |
| Token Endpoint | - | https://localhost:9443/oauth2/token |

## OpenAPI Specifications

Located in:
- `apis/AccountBalanceAPI/Definitions/swagger.yaml`
- `apis/CustomerProxyAPI/Definitions/swagger.yaml`
- `apis/LoanEligibilityAPI/Definitions/swagger.yaml`

These can be imported into Postman, Swagger UI, or any OpenAPI-compatible tool.
