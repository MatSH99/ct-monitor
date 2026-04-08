#!/bin/bash

TESSERACT_DIR="../tesseract/deployment/live/aws/test"
MONITOR_DIR="./infrastructure/live"

# --- 1. RETRIEVE DATA FROM TERRAGRUNT ---
echo "Retrieve infrastructure information from Terragrunt..."

export BUCKET_NAME=$(terragrunt output -raw -terragrunt-config $TESSERACT_DIR/terragrunt.hcl s3_bucket_name)
export DB_HOST=$(terragrunt output -raw -terragrunt-config $TESSERACT_DIR/terragrunt.hcl rds_aurora_cluster_endpoint)
export TESSERACT_SIGNER_ECDSA_P256_PUBLIC_KEY_ID=$(terragrunt output -raw -terragrunt-config $TESSERACT_DIR/terragrunt.hcl ecdsa_p256_public_key_id)
export TESSERACT_SIGNER_ECDSA_P256_PRIVATE_KEY_ID=$(terragrunt output -raw -terragrunt-config $TESSERACT_DIR/terragrunt.hcl ecdsa_p256_private_key_id)

# --- 2. RETRIEVE PASSWORD FROM SECRETS MANAGER ---
echo "Retrieve database password..."
SECRET_ARN=$(terragrunt output -json -terragrunt-config $TESSERACT_DIR/terragrunt.hcl rds_aurora_cluster_master_user_secret | jq --raw-output .[0].secret_arn)
export DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq --raw-output .password)

export DYNAMO_TABLE=$(terragrunt output -raw -terragrunt-config $MONITOR_DIR/terragrunt.hcl table_name)

export AWS_REGION="eu-central-1"
export TESSERA_BASE_NAME="test-static-ct"

# --- 4. DOCKER COMPOSE LAUNCH ---

if[ $# -eq 0]; then
  echo "Error: You should write which service you want to run"
else
  echo "Booting suite with Docker Compose..."
  docker compose "$@"
fi
