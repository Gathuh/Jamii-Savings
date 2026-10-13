#!/bin/bash
set -e

MI_URL="http://localhost:8290"
APIM_URL="https://localhost:9443"
GATEWAY_URL="https://localhost:8243"
FAILED=0

test_endpoint() {
    local name=$1
    local method=$2
    local url=$3
    local data=$4
    local expected_code=$5
    local expected_content=$6
    
    echo -n "Testing: $name... "
    
    if [ "$method" == "GET" ]; then
        response=$(curl -s -k -w "\n%{http_code}" "$url")
    else
        response=$(curl -s -k -w "\n%{http_code}" -X POST -H "Content-Type: application/json" -d "$data" "$url")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" != "$expected_code" ]; then
        echo "FAILED (expected $expected_code, got $http_code)"
        FAILED=1
        return 1
    fi
    
    if [ -n "$expected_content" ]; then
        if echo "$body" | grep -q "$expected_content"; then
            echo "PASSED"
        else
            echo "FAILED (content mismatch)"
            FAILED=1
            return 1
        fi
    else
        echo "PASSED"
    fi
}

echo "=========================================="
echo "Running MI Backend Tests"
echo "=========================================="

test_endpoint "AccountBalance - Valid Account" \
    "GET" "$MI_URL/accounts/ACC001/balance" "" "200" "ACC001"

test_endpoint "AccountBalance - Invalid Account" \
    "GET" "$MI_URL/accounts/INVALID999/balance" "" "404" "ACCOUNT_NOT_FOUND"

test_endpoint "CustomerProxy - Valid Customer" \
    "GET" "$MI_URL/customers/1" "" "200" "correlationId"

test_endpoint "LoanEligibility - Eligible" \
    "POST" "$MI_URL/loans/1.0.0/eligibility" \
    '{"customerId":"C123","monthlyIncome":50000,"loanAmount":20000,"loanTermMonths":12}' \
    "200" "\"eligible\":true"

test_endpoint "LoanEligibility - Not Eligible" \
    "POST" "$MI_URL/loans/1.0.0/eligibility" \
    '{"customerId":"C123","monthlyIncome":20000,"loanAmount":50000,"loanTermMonths":12}' \
    "200" "\"eligible\":false"

test_endpoint "LoanEligibility - Validation Error" \
    "POST" "$MI_URL/loans/1.0.0/eligibility" \
    '{"customerId":"C123"}' \
    "400" "INVALID_REQUEST"

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    echo "All tests PASSED"
    exit 0
else
    echo "Some tests FAILED"
    exit 1
fi
