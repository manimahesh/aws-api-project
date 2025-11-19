# Insecure API Demo - Educational Purposes Only

⚠️ **WARNING: This project contains intentional security vulnerabilities for educational purposes. DO NOT use in production environments!**

## Overview

This project demonstrates common API security vulnerabilities that developers should avoid. It's designed for cybersecurity education, security training, and demonstrating the importance of secure API development practices.

**Technology Stack:**
- 🚀 **AWS API Gateway HTTP API** (v2) - Fast, low-cost serverless API
- ⚡ **AWS Lambda** (Node.js 20.x) - Serverless compute
- 🌐 **S3 Static Website** - Frontend hosting
- 🔧 **Terraform** - Infrastructure as Code
- 🤖 **GitHub Actions** - CI/CD with OIDC

## Quick Links

- 🚀 [Quick Start Guide](QUICK-START.md) - Get running in 5 minutes
- 📖 [Detailed Deployment Guide](DEPLOYMENT.md) - Step-by-step instructions
- 🔐 [OIDC Configuration](docs/OIDC-CONFIGURATION.md) - GitHub OIDC setup help
- 📡 [HTTP API Migration](docs/HTTP-API-MIGRATION.md) - Why we use HTTP API instead of REST

## Security Vulnerabilities Demonstrated

### 1. **SQL Injection** (`/search` endpoint)
- User input is directly incorporated into SQL queries
- Demonstrates: `SELECT * FROM users WHERE username LIKE '%${query}%'`
- Try: `admin' OR '1'='1`

### 2. **Missing Authentication**
- All endpoints are accessible without any authentication
- No API keys, tokens, or credentials required
- Anyone can access sensitive operations

### 3. **Sensitive Data Exposure**
- Plain text passwords stored and returned in responses
- Social Security Numbers (SSN) exposed
- Credit card numbers visible
- Database credentials and API keys returned by `/admin/config`

### 4. **Mass Assignment** (`/users` POST endpoint)
- Users can set their own `isAdmin` field to `true`
- No field filtering or whitelisting
- Any JSON field in request body is accepted and stored

### 5. **Broken Access Control** (`/users/{userId}` PUT endpoint)
- Any user can update any other user's data
- No authorization checks
- Users can elevate their own privileges

### 6. **Insecure Direct Object References (IDOR)** (`/users/{userId}` GET endpoint)
- Sequential user IDs with no authorization
- Users can access other users' complete profiles
- No ownership verification

### 7. **Information Disclosure** (`/admin/config` endpoint)
- Exposes database connection strings
- Leaks API keys and secrets
- Returns encryption keys in plain text

### 8. **No Rate Limiting** (`/data/export` endpoint)
- Unlimited data export requests
- No throttling or DDoS protection
- Allows mass data exfiltration

### 9. **Overly Permissive CORS**
- `Access-Control-Allow-Origin: *`
- Allows requests from any domain
- No origin validation

### 10. **Verbose Error Messages**
- Stack traces exposed in error responses
- Internal implementation details leaked
- Helps attackers understand system internals

## Project Structure

```
aws-api-project/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions deployment workflow
├── terraform/
│   ├── modules/
│   │   ├── api_method/         # API Gateway method module
│   │   └── api_cors/           # API Gateway CORS module
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Terraform variables
│   ├── outputs.tf              # Terraform outputs
│   ├── github_oidc.tf          # GitHub OIDC configuration
│   └── terraform.tfvars.example # Example variables file
├── src/
│   └── index.js                # Lambda function handlers
├── public/
│   └── index.html              # Frontend HTML application
├── openapi.yaml                # API specification
├── package.json                # Node.js dependencies
└── README.md                   # This file
```

## API Endpoints

### 1. `GET /users`
Lists all users with all sensitive fields including passwords.

**Response:**
```json
[
  {
    "id": "1",
    "username": "admin",
    "password": "admin123",
    "email": "admin@example.com",
    "isAdmin": true,
    "ssn": "123-45-6789",
    "creditCard": "4532-1111-2222-3333"
  }
]
```

### 2. `POST /users`
Creates a new user. Vulnerable to mass assignment.

**Request:**
```json
{
  "username": "hacker",
  "password": "test123",
  "email": "hacker@test.com",
  "isAdmin": true
}
```

### 3. `GET /users/{userId}`
Gets a user by ID. No authorization check (IDOR vulnerability).

### 4. `PUT /users/{userId}`
Updates a user. Any user can update any other user (broken access control).

**Request:**
```json
{
  "isAdmin": true,
  "password": "newpassword"
}
```

### 5. `GET /search?query={query}`
Searches users. Vulnerable to SQL injection.

**Try:** `?query=admin' OR '1'='1`

### 6. `GET /admin/config`
Exposes sensitive configuration without authentication.

**Response:**
```json
{
  "databaseUrl": "postgresql://admin:secret123@db.example.com:5432/proddb",
  "apiKeys": {
    "stripeKey": "sk_live_51HxXXXXXXXXXXXXXXXXXXXX",
    "awsAccessKey": "AKIAIOSFODNN7EXAMPLE"
  },
  "secrets": {
    "jwtSecret": "super-secret-key-12345"
  }
}
```

### 7. `POST /data/export`
Exports all user data. No rate limiting or authorization.

**Request:**
```json
{
  "format": "json"
}
```

## Prerequisites

- AWS Account
- GitHub Account
- Terraform >= 1.0
- Node.js >= 20.x
- AWS CLI configured

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/aws-api-project.git
cd aws-api-project
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Check for Existing GitHub OIDC Provider (Optional)

If you already have a GitHub OIDC provider in your AWS account, check for it:

**On Linux/Mac:**
```bash
bash scripts/check-oidc-provider.sh
```

**On Windows (PowerShell):**
```powershell
.\scripts\check-oidc-provider.ps1
```

Or manually:
```bash
aws iam list-open-id-connect-providers
```

### 4. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and update:
```hcl
github_repo = "yourusername/aws-api-project"
aws_region  = "us-east-1"
environment = "dev"

# If you have an existing GitHub OIDC provider:
# use_existing_oidc_provider = true
# existing_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
```

### 5. Deploy Infrastructure with Terraform

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

**Important:** Terraform creates the Lambda function with a placeholder. You'll deploy the actual application code in the next step.

**Important Outputs:**
After deployment, Terraform will output:
- `api_gateway_url` - Your API Gateway endpoint
- `s3_website_url` - Your frontend website URL
- `github_actions_role_arn` - IAM role ARN for GitHub Actions
- `lambda_function_name` - Lambda function name
- `s3_bucket_name` - S3 bucket name
- `deployment_instructions` - Next steps

### 6. Deploy Application Code

Deploy the actual application code to Lambda using the provided script:

**On Windows (PowerShell):**
```powershell
.\scripts\deploy-lambda.ps1
```

**On Linux/Mac:**
```bash
bash scripts/deploy-lambda.sh
```

**Or manually:**
```bash
npm install
zip -r lambda.zip src/ package.json package-lock.json node_modules/
aws lambda update-function-code \
  --function-name $(cd terraform && terraform output -raw lambda_function_name) \
  --zip-file fileb://lambda.zip
```

### 7. Configure GitHub Secrets

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ROLE_ARN` | IAM role ARN from Terraform output | `arn:aws:iam::123456789012:role/...` |
| `AWS_REGION` | AWS region from Terraform output | `us-east-1` |
| `LAMBDA_FUNCTION_NAME` | Lambda function name | `insecure-api-demo-dev` |
| `S3_BUCKET_NAME` | S3 bucket name | `insecure-api-demo-frontend-dev-...` |
| `API_GATEWAY_ID` | API Gateway REST API ID | `abc123def4` |
| `STAGE_NAME` | API Gateway stage name | `dev` |

### 8. Deploy via GitHub Actions

Push to the `main` branch to trigger automatic deployment:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

GitHub Actions will:
1. Package the Lambda function
2. Authenticate to AWS using OIDC
3. Update Lambda function code
4. Deploy frontend to S3
5. Provide deployment URLs

### 9. Access the Application

1. Open the S3 website URL from Terraform outputs
2. Enter your API Gateway URL in the configuration field
3. Test the vulnerable endpoints

## Manual Deployment (Alternative)

If you prefer to deploy manually without GitHub Actions:

### Package Lambda Function
```bash
zip -r lambda.zip src/ package.json package-lock.json node_modules/
```

### Update Lambda Function
```bash
aws lambda update-function-code \
  --function-name insecure-api-demo-dev \
  --zip-file fileb://lambda.zip
```

### Deploy Frontend
```bash
aws s3 cp public/index.html s3://your-bucket-name/index.html \
  --content-type "text/html"
```

## How to Use for Security Training

### Demonstration Scenarios

#### 1. SQL Injection Attack
1. Open the frontend
2. Navigate to "Search Users"
3. Enter: `admin' OR '1'='1`
4. Observe how the query returns all users

#### 2. Mass Assignment Privilege Escalation
1. Use the "Create User" endpoint
2. Include `"isAdmin": true` in the JSON
3. Observe that a regular user was created with admin privileges

#### 3. IDOR Data Breach
1. Use "Get User by ID" with ID: 1
2. Try ID: 2, 3, etc.
3. Observe how you can access any user's sensitive data

#### 4. Information Disclosure
1. Call the "Get Config" endpoint
2. Observe exposed database credentials and API keys

#### 5. Broken Access Control
1. Get user ID 2's data
2. Use "Update User" to change user ID 2's password or admin status
3. Observe that you can modify other users' accounts

## Remediation Guide

### How to Fix These Vulnerabilities

#### 1. Fix SQL Injection
```javascript
// BAD
const query = `SELECT * FROM users WHERE username LIKE '%${userInput}%'`;

// GOOD - Use parameterized queries
const query = 'SELECT * FROM users WHERE username LIKE ?';
db.query(query, [`%${userInput}%`]);
```

#### 2. Add Authentication
```javascript
// Add JWT or API key validation
const token = event.headers.Authorization;
if (!token || !validateToken(token)) {
  return { statusCode: 401, body: 'Unauthorized' };
}
```

#### 3. Remove Sensitive Data from Responses
```javascript
// BAD
return { ...user };

// GOOD - Remove sensitive fields
const { password, ssn, creditCard, ...safeUser } = user;
return safeUser;
```

#### 4. Prevent Mass Assignment
```javascript
// BAD
const newUser = { ...requestBody };

// GOOD - Whitelist allowed fields
const { username, email } = requestBody;
const newUser = { username, email, isAdmin: false };
```

#### 5. Implement Authorization
```javascript
// Check if user can access resource
if (currentUser.id !== userId && !currentUser.isAdmin) {
  return { statusCode: 403, body: 'Forbidden' };
}
```

#### 6. Hash Passwords
```javascript
const bcrypt = require('bcrypt');

// Hash before storing
const hashedPassword = await bcrypt.hash(password, 10);

// Verify during login
const isValid = await bcrypt.compare(inputPassword, hashedPassword);
```

#### 7. Implement Rate Limiting
```javascript
// Use AWS API Gateway throttling
// Or implement application-level rate limiting
const rateLimiter = new RateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 100
});
```

#### 8. Restrict CORS
```javascript
// BAD
'Access-Control-Allow-Origin': '*'

// GOOD
const allowedOrigins = ['https://yourdomain.com'];
if (allowedOrigins.includes(origin)) {
  headers['Access-Control-Allow-Origin'] = origin;
}
```

## Testing

### Manual Testing with cURL

```bash
# List users
curl https://your-api-url.amazonaws.com/dev/users

# Create admin user (mass assignment)
curl -X POST https://your-api-url.amazonaws.com/dev/users \
  -H "Content-Type: application/json" \
  -d '{"username":"hacker","password":"test","email":"test@test.com","isAdmin":true}'

# SQL Injection
curl "https://your-api-url.amazonaws.com/dev/search?query=admin'%20OR%20'1'='1"

# Get sensitive config
curl https://your-api-url.amazonaws.com/dev/admin/config

# IDOR - Access another user's data
curl https://your-api-url.amazonaws.com/dev/users/2

# Broken access control - Update another user
curl -X PUT https://your-api-url.amazonaws.com/dev/users/2 \
  -H "Content-Type: application/json" \
  -d '{"isAdmin":true}'
```

## Cleanup

To destroy all AWS resources:

```bash
cd terraform
terraform destroy
```

**Note:** This will permanently delete:
- Lambda function
- API Gateway
- S3 bucket and contents
- IAM roles and policies
- CloudWatch log groups

## Security Best Practices (What This Project Violates)

- ✅ Always use parameterized queries
- ✅ Implement proper authentication and authorization
- ✅ Never store passwords in plain text
- ✅ Don't expose sensitive data in API responses
- ✅ Validate and sanitize all user input
- ✅ Use HTTPS for all communications
- ✅ Implement rate limiting and throttling
- ✅ Use restrictive CORS policies
- ✅ Don't expose stack traces or error details
- ✅ Follow principle of least privilege
- ✅ Implement proper session management
- ✅ Use UUIDs instead of sequential IDs
- ✅ Implement input validation and output encoding
- ✅ Regular security audits and penetration testing

## OWASP API Security Top 10

This project demonstrates several OWASP API Security Top 10 vulnerabilities:

1. **Broken Object Level Authorization** - IDOR vulnerabilities
2. **Broken Authentication** - No authentication implemented
3. **Broken Object Property Level Authorization** - Mass assignment
4. **Unrestricted Resource Consumption** - No rate limiting
5. **Broken Function Level Authorization** - Missing authorization checks
6. **Unrestricted Access to Sensitive Business Flows** - Export endpoint
7. **Server Side Request Forgery** - Not demonstrated
8. **Security Misconfiguration** - Overly permissive CORS, verbose errors
9. **Improper Inventory Management** - Not demonstrated
10. **Unsafe Consumption of APIs** - Not demonstrated

## Educational Use Cases

- Security training workshops
- Cybersecurity bootcamps
- Penetration testing practice
- Secure coding demonstrations
- University computer science courses
- Security awareness training
- DevSecOps education

## License

MIT License - See LICENSE file

## Disclaimer

This project is provided for educational purposes only. The authors and contributors are not responsible for any misuse of this code. Never deploy this in a production environment or expose it to the public internet without proper safeguards.

## Contributing

This is an educational project. If you have suggestions for additional vulnerabilities to demonstrate or improvements to the documentation, please open an issue or pull request.

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)

## Support

For questions or issues:
1. Check the documentation above
2. Review Terraform outputs for deployment URLs
3. Check GitHub Actions logs for deployment issues
4. Open a GitHub issue with details

---

**Remember: This is a deliberately vulnerable application. Use responsibly and only in controlled environments!**
