# Bonus Features

## Bonus A - Dashboard Aggregation API

### Endpoint

```
GET /dashboard/1.0.0/{customerId}/{accountNumber}?loanAmount=20000
```

### The Parallel Design Problem and Solution

The assignment required calling two or more backends in parallel. The challenge was that the original approach only took `customerId` as input, which meant AccountBalance could not be called without first knowing the account number - making true parallel calls impossible since one call would depend on the result of the previous one.

The solution was to redesign the request to accept both `customerId` and `accountNumber` as path parameters upfront. With both inputs known at the start of the request, CustomerProxy and AccountBalance have everything they need to fire independently without waiting for each other. This is what enables the parallel pattern.

LoanEligibility remains sequential because it depends on the balance returned by AccountBalance. You cannot calculate eligibility without knowing the balance first.

### Income Calculation

Instead of asking the caller to provide monthly income (which a branch system may not expose), the account balance is used as a proxy. Balance multiplied by 5 becomes the `monthlyIncome` passed to the eligibility engine. This reflects a real banking heuristic where borrowing capacity is proportional to available funds.

The `loanAmount` is passed as a query parameter so the caller specifies exactly how much they are requesting. This keeps the path clean, identity parameters in the path and request-specific parameters in the query, and avoids a POST body forwarding issue that would have broken the internal AccountBalance GET call.

### Call Flow

```
Request: GET /dashboard/1.0.0/{customerId}/{accountNumber}?loanAmount=20000
          |
          +-- CustomerProxy (customerId) -------+
          |                                     |-- both fire with known inputs
          +-- AccountBalance (accountNumber) ---+
                    |
                    | balance returned
                    |
          LoanEligibility (monthlyIncome = balance * 5, loanAmount from query param)
                    |
              Final merged response
```

### Partial Data Decision

If the account is not found the API still returns the customer profile rather than failing the whole response. The eligibility section is flagged as `eligible: false` with reason `No transaction history found`. A customer exists before an account exists and denying profile data because an account is missing would be the wrong behavior for a dashboard.

### Response Scenarios

**Full response (customer found, account found):**
```json
{
  "customerId": "1",
  "profile": { "name": "Leanne Graham", "email": "...", "phone": "..." },
  "account": { "accountNumber": "1001001001", "status": "ACTIVE", "balance": { "amount": 50000.0, "currency": "KES" } },
  "loanEligibility": { "eligible": true, "maxEligibleAmount": 230000, "eligibilityScore": 230000 }
}
```

**Partial response (customer found, account not found):**
```json
{
  "customerId": "6",
  "profile": { "name": "...", "email": "...", "phone": "..." },
  "account": null,
  "loanEligibility": { "eligible": false, "reason": "No transaction history found" }
}
```

**Not found:**
```json
{ "error": { "code": "CUSTOMER_NOT_FOUND", "status": 404 } }
```

### Test Commands

```bash
# Full response
curl -s "http://localhost:8290/dashboard/1.0.0/1/1001001001?loanAmount=20000"

# Partial response (customer 6 has no account)
curl -s "http://localhost:8290/dashboard/1.0.0/6/9999999999?loanAmount=20000"

# Customer not found
curl -s "http://localhost:8290/dashboard/1.0.0/99/1001001001?loanAmount=20000"
```

### Account to Customer Mapping

| customerId | accountNumber | Name |
|------------|---------------|------|
| 1 | 1001001001 | John Kamau |
| 2 | 1001001002 | Mary Wanjiku |
| 3 | 1001001003 | Peter Ochieng (DORMANT) |
| 4 | 1001001004 | Grace Muthoni (CLOSED) |
| 5 | 1001001005 | James Kiprop |
| 6-10 | No account | Partial data returned |

---

## Bonus B - RabbitMQ Message Queue Integration

### Overview

A loan officer or branch system publishes a loan application event to the `loan.applications` queue. WSO2 MI consumes it asynchronously, calls the Dashboard API to get the full customer picture, and routes the result based on account status and eligibility.

### Queues

| Queue | Purpose |
|-------|---------|
| `loan.applications` | Incoming loan application events |
| `loan.approved` | Applications where account is ACTIVE and eligible is true |
| `loan.rejected` | Applications where account is not ACTIVE or eligibility failed |
| `loan.deadletter` | Malformed or unprocessable messages with error reason |

### Message Flow

```
Producer publishes to loan.applications
        |
MI consumes message
        |
Validate required fields (customerId, accountNumber, loanAmount, loanTermMonths)
        |
        +-- Invalid --> loan.deadletter (with reason)
        |
Call Dashboard API
        |
        +-- Customer not found --> loan.rejected
        |
Check: accountStatus = ACTIVE AND eligible = true
        |
        +-- YES --> loan.approved
        +-- NO  --> loan.rejected (with reason)
```

### How This Differs From Request/Response APIs

The request/response APIs (AccountBalance, CustomerProxy, LoanEligibility) are synchronous. The caller sends a request and waits for a response. If something goes wrong the caller gets an error immediately and must decide whether to retry.

The message queue pattern is asynchronous. The caller publishes a message and moves on immediately without waiting. Retries are handled by the broker not the client. If MI is temporarily down the message stays in the queue and is processed when MI recovers. This means a branch system can accept loan applications even when the processing backend is under maintenance.

Malformed messages are not silently dropped. They are caught at validation and routed to `loan.deadletter` with the exact validation reason, giving operations teams visibility into bad data without losing the original message.

### Publishing a Test Message

Via RabbitMQ Management UI (http://localhost:15672, user: jamii, pass: jamii123):

1. Go to Queues and Streams
2. Click `loan.applications`
3. Expand Publish message
4. Paste payload and click Publish message

**Valid application (will be approved):**
```json
{"customerId":"1","accountNumber":"1001001001","loanAmount":20000,"loanTermMonths":12}
```

**Dormant account (will be rejected):**
```json
{"customerId":"3","accountNumber":"1001001003","loanAmount":10000,"loanTermMonths":6}
```

**Malformed message (will go to deadletter):**
```json
{"customerId":"1"}
```

### Checking Results

After publishing, go to Queues and Streams, click the relevant queue (`loan.approved`, `loan.rejected`, or `loan.deadletter`), expand Get messages, and click Get Message(s) to read the processed result.
