# GitHub OIDC Configuration Guide

This guide explains how to handle GitHub OIDC (OpenID Connect) provider configuration when deploying this project.

## What is GitHub OIDC?

GitHub OIDC allows GitHub Actions to authenticate to AWS without storing long-lived credentials (like AWS access keys). Instead, GitHub Actions requests a short-lived token from AWS using OpenID Connect.

## The Problem

AWS accounts can only have **one** OIDC provider for a given URL. If you already have a GitHub OIDC provider configured (from another project), Terraform will fail with an error like:

```
Error: creating IAM OIDC Provider (https://token.actions.githubusercontent.com): EntityAlreadyExists
```

## The Solution

This project supports **two deployment modes**:

### Mode 1: Create New OIDC Provider (Default)

Use this if you **don't** have a GitHub OIDC provider in your AWS account.

**Configuration:**
```hcl
# terraform.tfvars
use_existing_oidc_provider = false
```

Terraform will create a new GitHub OIDC provider for you.

### Mode 2: Use Existing OIDC Provider

Use this if you **already have** a GitHub OIDC provider in your AWS account.

**Configuration:**
```hcl
# terraform.tfvars
use_existing_oidc_provider = true
existing_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
```

Terraform will use your existing OIDC provider instead of creating a new one.

## How to Check for Existing OIDC Provider

### Option 1: Use the Helper Script

**On Linux/Mac:**
```bash
bash scripts/check-oidc-provider.sh
```

**On Windows (PowerShell):**
```powershell
.\scripts\check-oidc-provider.ps1
```

The script will:
- ✅ Check if a GitHub OIDC provider exists
- ✅ Show you the ARN if found
- ✅ Tell you the exact configuration to use

### Option 2: Manual Check with AWS CLI

```bash
aws iam list-open-id-connect-providers
```

Look for a provider with URL containing `token.actions.githubusercontent.com`:

```json
{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
        }
    ]
}
```

### Option 3: Check AWS Console

1. Go to AWS Console → IAM → Identity providers
2. Look for a provider with URL: `https://token.actions.githubusercontent.com`
3. Copy the ARN if it exists

## Step-by-Step Configuration

### Scenario 1: First Time Setup (No Existing Provider)

1. **Check for existing provider:**
   ```bash
   bash scripts/check-oidc-provider.sh
   ```

2. **If none found, use defaults:**
   ```hcl
   # terraform.tfvars
   use_existing_oidc_provider = false
   ```

3. **Deploy:**
   ```bash
   terraform apply
   ```

### Scenario 2: Already Have GitHub OIDC Provider

1. **Check for existing provider:**
   ```bash
   bash scripts/check-oidc-provider.sh
   ```

2. **Copy the ARN from the output:**
   ```
   ✓ GitHub OIDC provider found!
   ARN: arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
   ```

3. **Update terraform.tfvars:**
   ```hcl
   use_existing_oidc_provider = true
   existing_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
   ```

4. **Deploy:**
   ```bash
   terraform apply
   ```

## How It Works

The Terraform configuration uses conditional logic:

```hcl
# github_oidc.tf

# Only create new provider if use_existing_oidc_provider = false
resource "aws_iam_openid_connect_provider" "github" {
  count = var.use_existing_oidc_provider ? 0 : 1
  # ... provider configuration
}

# Use existing or newly created provider
locals {
  github_oidc_provider_arn = var.use_existing_oidc_provider ?
    var.existing_oidc_provider_arn :
    aws_iam_openid_connect_provider.github[0].arn
}
```

## IAM Role Configuration

The IAM role for GitHub Actions is **always created** regardless of which mode you use. The role:

- Is specific to **your repository** (configured via `github_repo` variable)
- Can only be assumed by GitHub Actions from your repository
- Has permissions to:
  - Update Lambda functions
  - Deploy to S3
  - Access API Gateway
  - Write CloudWatch logs

## Trust Policy

The IAM role's trust policy ensures only your GitHub repository can use it:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:yourusername/aws-api-project:*"
        }
      }
    }
  ]
}
```

## Troubleshooting

### Error: EntityAlreadyExists

**Problem:**
```
Error creating IAM OIDC Provider: EntityAlreadyExists: Provider with url
https://token.actions.githubusercontent.com already exists.
```

**Solution:**
1. Run the check script: `bash scripts/check-oidc-provider.sh`
2. Set `use_existing_oidc_provider = true` in `terraform.tfvars`
3. Set `existing_oidc_provider_arn` to the ARN shown by the script
4. Run `terraform apply` again

### Error: Invalid ARN

**Problem:**
```
Error: Invalid ARN format
```

**Solution:**
Make sure the ARN is in quotes and has the correct format:
```hcl
existing_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
```

### Error: Access Denied

**Problem:**
```
Error: AccessDenied: User is not authorized to perform: iam:GetOpenIDConnectProvider
```

**Solution:**
Your AWS credentials need IAM permissions. Ensure you have:
```json
{
  "Effect": "Allow",
  "Action": [
    "iam:GetOpenIDConnectProvider",
    "iam:ListOpenIDConnectProviders"
  ],
  "Resource": "*"
}
```

## Sharing OIDC Provider Across Projects

**Good news!** You can share one GitHub OIDC provider across **multiple** GitHub repositories.

Each project will:
- ✅ Use the **same** OIDC provider
- ✅ Create its **own** IAM role
- ✅ Restrict the role to its specific repository

**Example:**
```
OIDC Provider (Shared)
  └─ token.actions.githubusercontent.com
       ├─ Project 1 Role → Can only be used by repo: user/project1
       ├─ Project 2 Role → Can only be used by repo: user/project2
       └─ This Project Role → Can only be used by repo: user/aws-api-project
```

## Security Best Practices

1. **Unique IAM Roles:** Each project/repository should have its own IAM role
2. **Least Privilege:** Grant only the permissions needed for deployment
3. **Repository Restriction:** Use the `sub` condition to restrict to your repo
4. **Regular Audits:** Review IAM roles and their usage periodically
5. **OIDC Provider Thumbprint:** Terraform automatically manages this for you

## Additional Resources

- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC Provider Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Terraform aws_iam_openid_connect_provider Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider)

## Summary

| Situation | Configuration |
|-----------|---------------|
| First time using GitHub OIDC | `use_existing_oidc_provider = false` |
| Already have GitHub OIDC provider | `use_existing_oidc_provider = true`<br>`existing_oidc_provider_arn = "arn:..."` |
| Deploying multiple projects | Share one OIDC provider, create separate IAM roles |
| Switching between modes | Update `terraform.tfvars` and run `terraform apply` |

---

**Need help?** Run the check script first:
```bash
bash scripts/check-oidc-provider.sh
```
