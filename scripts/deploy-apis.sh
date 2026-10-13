#!/bin/bash
set -e

APIM_URL="https://localhost:9443"
ENV_NAME="docker"
APIS_DIR="./apis"

echo "Setting up apictl environment..."
apictl remove env $ENV_NAME 2>/dev/null || true
apictl add env $ENV_NAME --apim $APIM_URL

echo "Logging into APIM..."
apictl login $ENV_NAME -u admin -p admin -k

echo "Importing APIs..."

import_api() {
    local api_path=$1
    local api_name=$2
    echo "Importing $api_name..."
    if apictl import api -f "$api_path" -e $ENV_NAME -k --update; then
        echo "  $api_name imported successfully"
    else
        echo "  ERROR: Failed to import $api_name"
        exit 1
    fi
}

import_api "$APIS_DIR/AccountBalanceAPI" "AccountBalanceAPI"
import_api "$APIS_DIR/CustomerProxyAPI" "CustomerProxyAPI"
import_api "$APIS_DIR/LoanEligibilityAPI" "LoanEligibilityAPI"

echo ""
echo "Verifying API deployment..."
apictl get apis -e $ENV_NAME -k

PUBLISHED_COUNT=$(apictl get apis -e $ENV_NAME -k | grep -c "PUBLISHED" || true)
if [ "$PUBLISHED_COUNT" -lt 3 ]; then
    echo "ERROR: Not all APIs are published"
    exit 1
fi

echo ""
echo "All APIs deployed successfully"
