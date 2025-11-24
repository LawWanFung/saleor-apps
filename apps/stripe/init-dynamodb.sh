#!/bin/sh
set -e

echo "Checking DynamoDB RootConfig table..."

# 等 DynamoDB ready（最多 15 秒）
timeout=15
while ! aws dynamodb list-tables --endpoint-url ${AWS_ENDPOINT_URL_DYNAMODB:-http://localhost:8000} >/dev/null 2>&1; do
  timeout=$((timeout-1))
  if [ $timeout -eq 0 ]; then
    echo "DynamoDB local not reachable!"
    exit 1
  fi
  echo "Waiting for DynamoDB local..."
  sleep 1
done

# 創 table 如果冇
if ! aws dynamodb describe-table --table-name RootConfig --endpoint-url ${AWS_ENDPOINT_URL_DYNAMODB:-http://localhost:8000} >/dev/null 2>&1; then
  echo "Creating RootConfig table..."
  aws dynamodb create-table \
    --table-name RootConfig \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --endpoint-url ${AWS_ENDPOINT_URL_DYNAMODB:-http://localhost:8000} \
    --region ${AWS_REGION:-us-east-1}
else
  echo "RootConfig table already exists"
fi

# 跑原 CMD
echo "Starting Stripe app..."
exec "$@"
