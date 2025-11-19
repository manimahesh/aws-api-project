#!/bin/bash

# Script to deploy Lambda function code
# Run this after terraform apply to deploy the actual application code

set -e

echo "🚀 Deploying Lambda function code..."
echo ""

# Check if terraform directory exists
if [ ! -d "terraform" ]; then
    echo "❌ Error: terraform directory not found."
    echo "Please run this script from the project root directory."
    exit 1
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
    echo ""
fi

# Create deployment package
echo "📦 Creating deployment package..."
if [ -f "lambda.zip" ]; then
    rm lambda.zip
fi

zip -r lambda.zip src/ package.json package-lock.json node_modules/ > /dev/null
echo "✓ Package created: $(ls -lh lambda.zip | awk '{print $5}')"
echo ""

# Get function name from Terraform
echo "🔍 Getting Lambda function name from Terraform..."
cd terraform
FUNCTION_NAME=$(terraform output -raw lambda_function_name 2>/dev/null)

if [ -z "$FUNCTION_NAME" ]; then
    echo "❌ Error: Could not get Lambda function name from Terraform."
    echo "Make sure you've run 'terraform apply' first."
    exit 1
fi

echo "✓ Function name: $FUNCTION_NAME"
echo ""
cd ..

# Get AWS region from Terraform
cd terraform
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")
cd ..

# Deploy to Lambda
echo "🚀 Updating Lambda function code..."
aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://lambda.zip \
    --region "$AWS_REGION" \
    --no-cli-pager

echo ""
echo "⏳ Waiting for function update to complete..."
aws lambda wait function-updated \
    --function-name "$FUNCTION_NAME" \
    --region "$AWS_REGION"

echo ""
echo "✅ Lambda function deployed successfully!"
echo ""
echo "Next steps:"
echo "1. Open your frontend URL (from terraform output s3_website_url)"
echo "2. Enter your API Gateway URL in the frontend"
echo "3. Test the vulnerable endpoints"
echo ""
echo "To get your URLs:"
echo "  cd terraform && terraform output"
