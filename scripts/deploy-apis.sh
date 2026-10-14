#!/bin/bash
set -e

APIM_URL="https://localhost:9443"
ENV_NAME="docker"
APIS_DIR="./apis"

if ! command -v apictl &> /dev/null; then
    echo "apictl not found, downloading..."
    curl -L -o apictl.tar.gz https://github.com/wso2/product-apim-tooling/releases/download/v4.3.0/apictl-4.3.0-linux-amd64.tar.gz
    tar -xzf apictl.tar.gz
    export PATH=$PATH:$(pwd)/apictl
    echo "apictl installed"
fi

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
sleep 5
apictl get apis -e $ENV_NAME -k

echo ""
echo "All APIs imported successfully"
