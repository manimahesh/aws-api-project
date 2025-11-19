# Deployment Guide

This guide walks you through deploying the Insecure API Demo to AWS using Terraform and GitHub Actions.

## Prerequisites Checklist

- [ ] AWS Account with administrative access
- [ ] GitHub Account
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] Node.js >= 20.x installed
- [ ] Git installed

## Step-by-Step Deployment

### Step 1: Prepare Your Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/aws-api-project.git
   cd aws-api-project
   ```

2. **Install Node.js dependencies:**
   ```bash
   npm install
   ```

3. **Verify your AWS credentials:**
   ```bash
   aws sts get-caller-identity
   ```

### Step 2: Configure Terraform

1. **Navigate to the Terraform directory:**
   ```bash
   cd terraform
   ```

2. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars`:**
   ```hcl
   aws_region  = "us-east-1"  # Your preferred region
   environment = "dev"
   project_name = "insecure-api-demo"
   github_repo = "yourusername/aws-api-project"  # YOUR GITHUB REPO
   ```

   **Important:** Replace `yourusername/aws-api-project` with your actual GitHub repository.

### Step 3: Deploy Infrastructure with Terraform

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

   This downloads the required providers and modules.

2. **Validate the configuration:**
   ```bash
   terraform validate
   ```

3. **Review the execution plan:**
   ```bash
   terraform plan
   ```

   Review what resources will be created. You should see:
   - Lambda function
   - API Gateway REST API
   - S3 bucket for frontend
   - IAM roles and policies
   - CloudWatch log groups
   - OIDC provider for GitHub

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

   Type `yes` when prompted.

5. **Save the outputs:**
   ```bash
   terraform output
   ```

   You'll see output like:
   ```
   api_gateway_url = "https://abc123def.execute-api.us-east-1.amazonaws.com/dev"
   github_actions_role_arn = "arn:aws:iam::123456789012:role/insecure-api-demo-github-actions-dev"
   lambda_function_name = "insecure-api-demo-dev"
   s3_bucket_name = "insecure-api-demo-frontend-dev-123456789012"
   s3_website_url = "http://insecure-api-demo-frontend-dev-123456789012.s3-website-us-east-1.amazonaws.com"
   api_gateway_id = "abc123def"
   ```

   **Save these values - you'll need them for GitHub configuration!**

   **Note:** Terraform creates the Lambda function with a placeholder. You'll deploy the actual application code in the next step.

### Step 4: Deploy Application Code to Lambda

Now deploy the actual application code to the Lambda function:

**First, install dependencies and create the package:**
```bash
# Return to project root
cd ..

# Install Node.js dependencies
npm install

# Create deployment package
zip -r lambda.zip src/ package.json package-lock.json node_modules/

# Verify the package
ls -lh lambda.zip
```

**Then deploy to Lambda:**
```bash
# Get the function name from Terraform output
FUNCTION_NAME=$(cd terraform && terraform output -raw lambda_function_name)

# Update Lambda function code
aws lambda update-function-code \
  --function-name $FUNCTION_NAME \
  --zip-file fileb://lambda.zip \
  --region us-east-1

# Wait for the update to complete
aws lambda wait function-updated \
  --function-name $FUNCTION_NAME \
  --region us-east-1

echo "Lambda function updated successfully!"
```

### Step 5: Configure GitHub Repository

1. **Push your code to GitHub:**
   ```bash
   git add .
   git commit -m "Initial commit: Insecure API Demo"
   git branch -M main
   git remote add origin https://github.com/yourusername/aws-api-project.git
   git push -u origin main
   ```

2. **Navigate to GitHub repository settings:**
   - Go to your repository on GitHub
   - Click "Settings"
   - Navigate to "Secrets and variables" → "Actions"

3. **Add the following secrets:**

   Click "New repository secret" for each:

   | Secret Name | Value | Where to find it |
   |-------------|-------|------------------|
   | `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/...` | Terraform output: `github_actions_role_arn` |
   | `AWS_REGION` | `us-east-1` | Terraform output: `aws_region` |
   | `LAMBDA_FUNCTION_NAME` | `insecure-api-demo-dev` | Terraform output: `lambda_function_name` |
   | `S3_BUCKET_NAME` | `insecure-api-demo-frontend-dev-...` | Terraform output: `s3_bucket_name` |
   | `API_GATEWAY_ID` | `abc123def` | Terraform output: `api_gateway_id` |
   | `STAGE_NAME` | `dev` | Your environment from terraform.tfvars |

### Step 6: Test GitHub Actions Deployment

1. **Trigger the workflow manually:**
   - Go to "Actions" tab in GitHub
   - Select "Deploy Insecure API Demo"
   - Click "Run workflow"
   - Select the `main` branch
   - Click "Run workflow"

2. **Monitor the deployment:**
   - Watch the workflow execution in real-time
   - Check for any errors in the logs

3. **Verify deployment success:**
   - Workflow should complete successfully
   - Check the deployment summary for URLs

### Step 7: Access Your Application

1. **Open the frontend:**
   - Use the `s3_website_url` from Terraform outputs
   - Example: `http://insecure-api-demo-frontend-dev-123456789012.s3-website-us-east-1.amazonaws.com`

2. **Configure the frontend:**
   - Enter your API Gateway URL in the configuration field
   - Example: `https://abc123def.execute-api.us-east-1.amazonaws.com/dev`

3. **Test the endpoints:**
   - Click any endpoint button to test
   - Observe the vulnerable behaviors

### Step 8: Verify All Endpoints

Test each endpoint to ensure deployment was successful:

1. **List Users** - Should return mock users with passwords
2. **Create User** - Try creating a user with `isAdmin: true`
3. **Get User by ID** - Try accessing user IDs 1, 2, 3
4. **Update User** - Try modifying another user
5. **Search Users** - Try SQL injection: `admin' OR '1'='1`
6. **Get Config** - Should expose fake credentials
7. **Export Data** - Should export all users in selected format

## Troubleshooting

### Issue: Terraform apply fails with "bucket already exists"

**Solution:**
```bash
# Choose a unique bucket name in terraform.tfvars
# Or let AWS generate a unique name (default behavior)
```

### Issue: GitHub Actions can't assume the role

**Solutions:**
1. Verify `AWS_ROLE_ARN` secret is correct
2. Check that `github_repo` in terraform.tfvars matches your repository
3. Ensure the repository is set to public or the OIDC trust policy allows private repos

### Issue: Lambda function update fails

**Solutions:**
1. Check the function name matches Terraform output
2. Verify the lambda.zip file exists and is valid
3. Ensure AWS credentials are configured correctly

### Issue: API Gateway returns 500 errors

**Solutions:**
1. Check Lambda function logs in CloudWatch
2. Verify Lambda has execution permissions
3. Test Lambda function directly in AWS Console

### Issue: Frontend can't connect to API

**Solutions:**
1. Verify CORS is enabled (should be automatic)
2. Check API Gateway URL is correct in frontend
3. Ensure API Gateway deployment completed successfully

### Issue: S3 website returns 403 Forbidden

**Solutions:**
1. Verify bucket policy allows public read access
2. Check public access block settings are disabled
3. Ensure index.html was uploaded correctly

## Useful Commands

### View Terraform state
```bash
cd terraform
terraform show
```

### View Terraform outputs
```bash
terraform output
```

### Refresh Terraform outputs
```bash
terraform refresh
```

### Update only Lambda function
```bash
aws lambda update-function-code \
  --function-name $(terraform output -raw lambda_function_name) \
  --zip-file fileb://lambda.zip
```

### View Lambda logs
```bash
aws logs tail /aws/lambda/insecure-api-demo-dev --follow
```

### Test API endpoint
```bash
curl $(terraform output -raw api_gateway_url)/users
```

### Sync frontend to S3
```bash
aws s3 cp public/index.html s3://$(terraform output -raw s3_bucket_name)/index.html
```

## Continuous Deployment

After initial setup, any push to the `main` branch will automatically:

1. Package the Lambda function
2. Authenticate to AWS via OIDC
3. Update Lambda function code
4. Deploy frontend to S3
5. Provide deployment summary

To deploy changes:
```bash
git add .
git commit -m "Update API functionality"
git push origin main
```

## Manual Updates (Without GitHub Actions)

If you prefer manual deployments:

### Update Lambda Function
```bash
# Create package
zip -r lambda.zip src/ package.json package-lock.json node_modules/

# Deploy
aws lambda update-function-code \
  --function-name insecure-api-demo-dev \
  --zip-file fileb://lambda.zip \
  --region us-east-1
```

### Update Frontend
```bash
aws s3 cp public/index.html \
  s3://your-bucket-name/index.html \
  --content-type "text/html"
```

### Update Infrastructure
```bash
cd terraform
terraform apply
```

## Cleanup and Teardown

To completely remove all resources:

1. **Destroy infrastructure:**
   ```bash
   cd terraform
   terraform destroy
   ```

   Type `yes` when prompted.

2. **Verify deletion:**
   - Check AWS Console for any remaining resources
   - Confirm S3 bucket is deleted
   - Verify Lambda function is removed

3. **Clean local files:**
   ```bash
   cd ..
   rm -f lambda.zip
   rm -rf node_modules/
   ```

## Cost Estimation

This deployment should cost minimal amounts:

- **Lambda:** Free tier covers 1M requests/month
- **API Gateway:** Free tier covers 1M requests/month
- **S3:** Minimal storage costs (~$0.023/GB)
- **CloudWatch Logs:** 5GB free per month

**Estimated monthly cost:** < $1 (within free tier limits)

## Security Recommendations for Educational Use

1. **Restrict access** - Use AWS IAM to limit who can access resources
2. **Set up billing alerts** - Monitor AWS costs
3. **Use separate AWS account** - Isolate from production resources
4. **Delete when done** - Run `terraform destroy` after training
5. **Don't expose publicly** - Keep URLs private or use VPN
6. **Monitor usage** - Check CloudWatch logs regularly

## Next Steps

After successful deployment:

1. Review the [README.md](README.md) for vulnerability details
2. Try the demonstration scenarios
3. Practice identifying and exploiting vulnerabilities
4. Learn the remediation techniques
5. Use for security training sessions

---

**Need Help?**
- Check GitHub Actions logs for deployment issues
- Review CloudWatch logs for runtime errors
- Open a GitHub issue with details and error messages
