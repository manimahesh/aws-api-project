#!/bin/bash

# Script to check if GitHub OIDC provider already exists in AWS account

echo "Checking for existing GitHub OIDC provider..."
echo ""

# List all OIDC providers
PROVIDERS=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[*].Arn' --output text)

if [ -z "$PROVIDERS" ]; then
    echo "No OIDC providers found in your AWS account."
    echo ""
    echo "You can proceed with the default configuration:"
    echo "  use_existing_oidc_provider = false"
    exit 0
fi

# Check for GitHub OIDC provider
GITHUB_PROVIDER=""
for provider in $PROVIDERS; do
    if [[ $provider == *"token.actions.githubusercontent.com"* ]]; then
        GITHUB_PROVIDER=$provider
        break
    fi
done

if [ -n "$GITHUB_PROVIDER" ]; then
    echo "✓ GitHub OIDC provider found!"
    echo ""
    echo "ARN: $GITHUB_PROVIDER"
    echo ""
    echo "Update your terraform.tfvars with:"
    echo ""
    echo "use_existing_oidc_provider = true"
    echo "existing_oidc_provider_arn = \"$GITHUB_PROVIDER\""
    echo ""

    # Get provider details
    echo "Provider details:"
    aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$GITHUB_PROVIDER"
else
    echo "No GitHub OIDC provider found."
    echo ""
    echo "Found these OIDC providers:"
    echo "$PROVIDERS"
    echo ""
    echo "You can proceed with the default configuration:"
    echo "  use_existing_oidc_provider = false"
fi
