#!/bin/bash
set -e

MAX_RETRIES=60
RETRY_INTERVAL=10

wait_for_service() {
    local name=$1
    local url=$2
    local retries=0
    
    echo "Waiting for $name..."
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -s -k -f "$url" > /dev/null 2>&1; then
            echo "$name is ready"
            return 0
        fi
        retries=$((retries + 1))
        echo "  Attempt $retries/$MAX_RETRIES - $name not ready, waiting ${RETRY_INTERVAL}s..."
        sleep $RETRY_INTERVAL
    done
    echo "ERROR: $name failed to start"
    return 1
}

wait_for_service "MySQL" "http://localhost:3307" || true
wait_for_service "WSO2 MI" "http://localhost:9201/healthz"
wait_for_service "WSO2 APIM" "https://localhost:9443/services/Version"

echo "All services are ready"
