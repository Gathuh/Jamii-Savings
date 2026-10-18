# Part 2: API Manager Integration

## Overview

This document describes how the three Jamii Savings Bank APIs are exposed through WSO2 API Manager, including security, throttling, gateway policies, backend service choices, and how a consuming application subscribes via the Developer Portal.

## Published APIs

| API Name | Context | Version | Throttling Tier | Security |
|----------|---------|---------|-----------------|----------|
| AccountBalanceAPI | /accounts | 1.0.0 | Unlimited | OAuth2 |
| CustomerProxyAPI | /customers | 1.0.0 | Unlimited | OAuth2 |
| LoanEligibilityAPI | /loans | 1.0.0 | Gold | OAuth2 |

## Backend Service Choices

**CustomerProxyAPI - JSONPlaceholder**
JSONPlaceholder (jsonplaceholder.typicode.com) was chosen as it provides a realistic REST API returning structured user data (name, email, address, company) that mirrors what a real CRM would return. It requires no authentication setup, making it self-contained for evaluation. In production this would be replaced with the bank's internal CRM behind mutual TLS.

**LoanEligibilityAPI - SOAP Calculator (testingapis.com)**
The calculator at api.testingapis.com/api/soap/calculator was chosen because it is a publicly accessible SOAP service that demonstrates real protocol transformation without requiring a local SOAP server. The request/response mapping is:

- `monthlyIncome` maps to `intA` (the larger value)
- `loanAmount` maps to `intB` (the value to subtract)
- `SubtractResult` (income minus loan amount) becomes the `eligibilityScore`
- A positive score means income exceeds the loan amount - customer is eligible
- A negative score means loan exceeds affordable limit - customer is not eligible

## Throttling Tier Rationale

**LoanEligibilityAPI uses the Gold tier** because loan eligibility checks are computationally expensive SOAP operations with an external dependency. Rate limiting this API prevents abuse and protects the downstream calculator service. AccountBalanceAPI and CustomerProxyAPI use Unlimited as balance lookups and customer reads are expected to support high-frequency polling from internal systems.

## Security Scheme

All three APIs use OAuth2 with the client credentials flow. Tokens are issued by the APIM token endpoint and passed as Bearer tokens on every request.

## Custom Gateway Mediation Policy

**AccountBalanceAPI** has a custom gateway policy that injects an `X-Bank-Name: JamiiSavings` header on every request. This allows downstream systems and audit logs to identify the originating bank and API without inspecting the request body. The policy is defined at `apis/AccountBalanceAPI/Policies/add-bank-header.xml`.

## API Product

**JamiiBankingProduct** bundles all three APIs under a single subscription at context `/jamii-banking`. A developer subscribing to the product gets access to all three APIs with one set of credentials, simplifying onboarding. The product definition is at `apis/JamiiBankingProduct/api_product.yaml`.

## Developer Portal Subscription Guide

1. Go to https://localhost:9443/devportal and log in
2. Click Applications, then Add New Application, name it and save
3. Go to the API you want (or JamiiBankingProduct for all three), click Subscribe, select your application
4. Go to Applications, your app, Production Keys, click Generate Keys
5. Copy the Consumer Key and Consumer Secret and generate a token:

```bash
curl -k -X POST https://localhost:9443/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "<ConsumerKey>:<ConsumerSecret>" \
  -d "grant_type=client_credentials"
```

## Testing

### Direct Against MI (No Token Required)

```bash
curl -s http://localhost:8290/accounts/1.0.0/ACC001/balance

curl -s http://localhost:8290/customers/1.0.0/1

curl -s -X POST http://localhost:8290/loans/1.0.0/eligibility \
  -H "Content-Type: application/json" \
  -d '{"customerId":"C123","monthlyIncome":50000,"loanAmount":20000,"loanTermMonths":12}'
```

### Via APIM Gateway (OAuth2 Required)

```bash
curl -k https://localhost:8243/accounts/1.0.0/ACC001/balance \
  -H "Authorization: Bearer <your_token>"

curl -k https://localhost:8243/customers/1.0.0/1 \
  -H "Authorization: Bearer <your_token>"

curl -k -X POST https://localhost:8243/loans/1.0.0/eligibility \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{"customerId":"C123","monthlyIncome":50000,"loanAmount":20000,"loanTermMonths":12}'
```

### Gateway URLs

| Environment | HTTPS |
|-------------|-------|
| Gateway | https://localhost:8243 |
| Token Endpoint | https://localhost:9443/oauth2/token |

### OpenAPI Specifications

Located at `apis/{API}/Definitions/swagger.yaml` for each API. These can be imported into Postman or Swagger UI.

## Bonus A - Dashboard Aggregation API

### Endpoint

```
GET /dashboard/1.0.0/{customerId}?accountNumber={accountNumber}
```

### Design Decision: Sequential with Partial Data

The assignment suggested parallel calls. After analysis, a hybrid approach was chosen. CustomerProxy and AccountBalance are called with inputs provided upfront in the request (customerId and accountNumber as a query parameter), so they could fire independently. However LoanEligibility depends on the balance returned by AccountBalance (balance x 5 is used as monthlyIncome), making it strictly sequential.

The hierarchy is:

1. Call CustomerProxy (customerId) - if customer not found, stop and return 404
2. Call AccountBalance (accountNumber) - if no account, return profile only, skip eligibility
3. Call LoanEligibility (balance x 5 as monthlyIncome) - only if account found

If account is missing, loan eligibility returns `eligible: false` with reason "No transaction history found" rather than failing the whole response. This means a customer with no account still gets their profile data.

### Response Scenarios

**Customer found, account found:**
```json
{
  "customerId": "1",
  "profile": { "name": "Leanne Graham", "email": "...", "phone": "..." },
  "account": { "accountNumber": "1001001001", "status": "ACTIVE", "balance": { "amount": 50000.0, "currency": "KES" } },
  "loanEligibility": { "eligible": true, "maxEligibleAmount": 200000, "eligibilityScore": 200000 }
}
```

**Customer found, no account:**
```json
{
  "customerId": "6",
  "profile": { "name": "...", "email": "...", "phone": "..." },
  "account": null,
  "loanEligibility": { "eligible": false, "reason": "No transaction history found" }
}
```

**Customer not found:**
```json
{ "error": { "code": "CUSTOMER_NOT_FOUND", "status": 404 } }
```

### Testing

```bash
# Full response (customer + account + eligibility)
curl -s "http://localhost:8290/dashboard/1.0.0/1?accountNumber=1001001001"

# Partial response (customer only, no account)
curl -s "http://localhost:8290/dashboard/1.0.0/6"

# Not found
curl -s "http://localhost:8290/dashboard/1.0.0/99"
```

### Account to Customer Mapping

| customerId | accountNumber |
|------------|---------------|
| 1 | 1001001001 |
| 2 | 1001001002 |
| 3 | 1001001003 |
| 4 | 1001001004 |
| 5 | 1001001005 |
| 6-10 | No account (partial data returned) |
