# Quick Start Guide

Get up and running in 5 minutes!

## Prerequisites

- ✅ AWS Account
- ✅ AWS CLI configured
- ✅ GitHub Account
- ✅ Terraform installed
- ✅ Node.js installed

## Quick Setup

### 1. Check for Existing GitHub OIDC Provider

**Windows (PowerShell):**
```powershell
.\scripts\check-oidc-provider.ps1
```

**Linux/Mac:**
```bash
bash scripts/check-oidc-provider.sh
```

### 2. Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

**Edit `terraform.tfvars`:**
```hcl
github_repo = "yourusername/aws-api-project"  # CHANGE THIS!

# If the script found an existing OIDC provider, add:
# use_existing_oidc_provider = true
# existing_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
```

### 3. Deploy

```bash
terraform init
terraform apply
```

Type `yes` when prompted.

### 4. Deploy Application Code

Return to project root and run the deployment script:

**Windows (PowerShell):**
```powershell
cd ..
.\scripts\deploy-lambda.ps1
```

**Linux/Mac:**
```bash
cd ..
bash scripts/deploy-lambda.sh
```

This will install dependencies, package your code, and deploy to Lambda.

### 5. Save Terraform Outputs

```bash
cd terraform
terraform output
```

Copy these values - you'll need them for GitHub!

### 6. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets using the values from Terraform output:

| Secret Name | Source |
|-------------|--------|
| `AWS_ROLE_ARN` | `github_actions_role_arn` output |
| `AWS_REGION` | `aws_region` output |
| `LAMBDA_FUNCTION_NAME` | `lambda_function_name` output |
| `S3_BUCKET_NAME` | `s3_bucket_name` output |
| `API_GATEWAY_ID` | `api_gateway_id` output |
| `STAGE_NAME` | `dev` (or your environment) |

### 7. Push to GitHub

```bash
cd ..  # Return to project root if needed
git add .
git commit -m "Initial deployment"
git push origin main
```

### 8. Access Your Application

Open the URL from Terraform output `s3_website_url` and start testing!

## Testing the Vulnerabilities

Once deployed, try these demonstrations:

### 1. SQL Injection
In the frontend, use the "Search Users" endpoint with:
```
admin' OR '1'='1
```

### 2. Mass Assignment
Create a user with admin privileges:
```json
{
  "username": "hacker",
  "password": "test123",
  "isAdmin": true
}
```

### 3. IDOR
Access another user's data by trying different IDs (1, 2, 3).

### 4. Information Disclosure
Call the "Get Config" endpoint to see exposed credentials.

## Cleanup

When done, destroy everything:

```bash
cd terraform
terraform destroy
```

Type `yes` to confirm.

## Need More Help?

- 📖 [Full README](README.md)
- 🔐 [OIDC Configuration Guide](docs/OIDC-CONFIGURATION.md)
- 🚀 [Detailed Deployment Guide](DEPLOYMENT.md)

## Common Issues

### Issue: "EntityAlreadyExists" error

**Fix:** You already have a GitHub OIDC provider. Run the check script and update `terraform.tfvars`:
```hcl
use_existing_oidc_provider = true
existing_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
```

### Issue: GitHub Actions fails

**Fix:** Double-check all 5 GitHub secrets are set correctly using values from `terraform output`.

### Issue: Frontend can't connect to API

**Fix:** Enter the full API Gateway URL in the frontend's configuration field.

---

**Ready to start? Begin with step 1! ⬆️**
