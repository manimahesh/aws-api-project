# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          GitHub Actions                          │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  1. Push to main branch                                │     │
│  │  2. Workflow triggers                                  │     │
│  │  3. Request OIDC token                                 │     │
│  └────────────────────────┬───────────────────────────────┘     │
└─────────────────────────────┼───────────────────────────────────┘
                              │
                              │ OIDC Token
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Account                               │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  GitHub OIDC Provider                                │       │
│  │  • URL: token.actions.githubusercontent.com          │       │
│  │  • Validates GitHub tokens                           │       │
│  │  • Issues temporary AWS credentials                  │       │
│  └────────────────┬─────────────────────────────────────┘       │
│                   │                                              │
│                   │ Assume Role                                  │
│                   ↓                                              │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  IAM Role: github-actions-role                       │       │
│  │  • Condition: repo = "user/aws-api-project:*"        │       │
│  │  • Permissions:                                      │       │
│  │    - Lambda: UpdateFunctionCode                      │       │
│  │    - S3: PutObject, GetObject                        │       │
│  │    - API Gateway: GET, POST, PUT, PATCH              │       │
│  │    - CloudWatch: CreateLogGroup, PutLogEvents        │       │
│  └────────────────┬─────────────────────────────────────┘       │
│                   │                                              │
│                   │ Deploy                                       │
│                   ↓                                              │
│  ┌──────────────────────────────────────────────────────┐       │
│  │                 Lambda Function                      │       │
│  │  ┌──────────────────────────────────────────────┐    │       │
│  │  │  src/index.js                                │    │       │
│  │  │  • Route requests                            │    │       │
│  │  │  • Handle all API endpoints                  │    │       │
│  │  │  • Return vulnerable responses               │    │       │
│  │  └──────────────────────────────────────────────┘    │       │
│  └───────────────┬──────────────────────────────────────┘       │
│                  │                                               │
│                  │ Invoked by                                    │
│                  ↓                                               │
│  ┌──────────────────────────────────────────────────────┐       │
│  │         API Gateway (REST API)                       │       │
│  │  Endpoints:                                          │       │
│  │  • GET    /users                                     │       │
│  │  • POST   /users                                     │       │
│  │  • GET    /users/{userId}                            │       │
│  │  • PUT    /users/{userId}                            │       │
│  │  • GET    /search?query={query}                      │       │
│  │  • GET    /admin/config                              │       │
│  │  • POST   /data/export                               │       │
│  │                                                       │       │
│  │  CORS: * (Allow All) ⚠️                              │       │
│  │  Auth: None ⚠️                                       │       │
│  └───────────────┬──────────────────────────────────────┘       │
│                  │                                               │
│                  │ Logs to                                       │
│                  ↓                                               │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              CloudWatch Logs                         │       │
│  │  • API Gateway access logs                           │       │
│  │  • Lambda execution logs                             │       │
│  │  • Retention: 7 days                                 │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐       │
│  │           S3 Bucket (Static Website)                 │       │
│  │  ┌──────────────────────────────────────────────┐    │       │
│  │  │  index.html                                  │    │       │
│  │  │  • Interactive UI                            │    │       │
│  │  │  • Endpoint testing                          │    │       │
│  │  │  • Response viewer                           │    │       │
│  │  └──────────────────────────────────────────────┘    │       │
│  │                                                       │       │
│  │  Configuration:                                       │       │
│  │  • Public read access                                │       │
│  │  • Static website hosting enabled                    │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↑
                              │
                              │ HTTPS Requests
                              │
                    ┌─────────────────┐
                    │   End Users     │
                    │  (Browser)      │
                    └─────────────────┘
```

## Request Flow

### User Interacts with Frontend

1. **User opens S3 website URL**
   ```
   http://bucket-name.s3-website-us-east-1.amazonaws.com
   ```

2. **User enters API Gateway URL in frontend**
   ```
   https://api-id.execute-api.us-east-1.amazonaws.com/dev
   ```

3. **User clicks endpoint button (e.g., "List Users")**

### API Request Flow

```
Browser
   │
   │ HTTP GET /users
   ↓
API Gateway
   │
   │ Validate request (No auth ⚠️)
   │ Add CORS headers
   │
   ↓
Lambda Function
   │
   │ Parse event
   │ Route to handler
   │ Query mock database
   │ Return sensitive data ⚠️
   │
   ↓
API Gateway
   │
   │ Return response with CORS
   │
   ↓
Browser
   │
   └─→ Display JSON response
```

## Deployment Flow

### Manual Terraform Deployment

```
Developer Machine
   │
   │ 1. terraform init
   │ 2. terraform plan
   │ 3. terraform apply
   ↓
AWS CloudFormation (via Terraform)
   │
   ├─→ Create Lambda Function
   ├─→ Create API Gateway
   ├─→ Create S3 Bucket
   ├─→ Create IAM Roles
   ├─→ Create OIDC Provider (if not exists)
   └─→ Configure CloudWatch Logs
```

### GitHub Actions Deployment

```
Developer
   │
   │ git push origin main
   ↓
GitHub Actions Workflow
   │
   ├─→ 1. Checkout code
   ├─→ 2. Setup Node.js
   ├─→ 3. Install dependencies
   ├─→ 4. Create lambda.zip
   │
   ├─→ 5. Request OIDC token
   │      └─→ GitHub issues JWT token
   │
   ├─→ 6. Assume AWS role via OIDC
   │      └─→ AWS STS returns temporary credentials
   │
   ├─→ 7. Update Lambda function
   │      └─→ Upload new lambda.zip
   │
   ├─→ 8. Deploy frontend to S3
   │      └─→ Upload index.html
   │
   └─→ 9. Output deployment URLs
```

## OIDC Authentication Flow

```
GitHub Actions
   │
   │ 1. Request OIDC token
   │    Subject: repo:user/project:ref:refs/heads/main
   ↓
GitHub Token Service
   │
   │ 2. Issue JWT token
   │    Audience: sts.amazonaws.com
   │    Issuer: https://token.actions.githubusercontent.com
   ↓
AWS STS (via OIDC Provider)
   │
   │ 3. Validate token
   │    • Verify signature
   │    • Check audience
   │    • Validate subject matches condition
   │
   ├─→ Match IAM Role trust policy
   │
   ↓
   │ 4. Issue temporary credentials
   │    • Access Key ID
   │    • Secret Access Key
   │    • Session Token
   │    • Expiration: 1 hour
   ↓
GitHub Actions
   │
   └─→ 5. Use credentials for deployment
```

## Security Vulnerabilities Map

```
Frontend (S3)
   │
   │ ⚠️ No input validation
   │ ⚠️ Trusts all API responses
   ↓
API Gateway
   │
   │ ⚠️ No authentication
   │ ⚠️ Overly permissive CORS (*)
   │ ⚠️ No rate limiting
   ↓
Lambda Function
   │
   ├─→ /users
   │   └─→ ⚠️ Returns passwords in plain text
   │       ⚠️ Exposes SSN and credit cards
   │
   ├─→ /users (POST)
   │   └─→ ⚠️ Mass assignment vulnerability
   │       ⚠️ Users can set isAdmin=true
   │
   ├─→ /users/{userId}
   │   └─→ ⚠️ IDOR - no authorization check
   │       ⚠️ Sequential IDs
   │
   ├─→ /search
   │   └─→ ⚠️ SQL Injection vulnerability
   │       ⚠️ Direct query construction
   │
   ├─→ /admin/config
   │   └─→ ⚠️ Information disclosure
   │       ⚠️ Exposes database credentials
   │       ⚠️ Returns API keys and secrets
   │
   └─→ /data/export
       └─→ ⚠️ No rate limiting
           ⚠️ Allows mass data export
           ⚠️ No authorization
```

## Infrastructure as Code

### Terraform Module Structure

```
terraform/
│
├─ main.tf                  # Main infrastructure
│  ├─ Lambda function
│  ├─ API Gateway REST API
│  ├─ S3 bucket
│  └─ CloudWatch logs
│
├─ github_oidc.tf          # OIDC provider & IAM role
│  ├─ GitHub OIDC provider (conditional)
│  ├─ IAM role for GitHub Actions
│  └─ IAM policies
│
├─ variables.tf            # Input variables
├─ outputs.tf              # Output values
├─ terraform.tfvars        # Variable values (gitignored)
│
└─ modules/
   ├─ api_method/          # Reusable API method module
   │  └─ Creates method + integration
   │
   └─ api_cors/            # Reusable CORS module
      └─ Creates OPTIONS method
```

## Cost Estimation

```
Monthly Costs (within AWS Free Tier):

Lambda
└─ 1M requests/month FREE
   └─ Additional: $0.20 per 1M requests

API Gateway
└─ 1M requests/month FREE
   └─ Additional: $3.50 per 1M requests

S3
└─ Storage: $0.023/GB
   └─ index.html: ~$0.0001/month
   └─ Requests: Minimal cost

CloudWatch Logs
└─ 5GB ingestion FREE
   └─ Storage: $0.03/GB after 1 month

Total Estimated Cost: < $1/month
(assuming moderate educational use)
```

## Monitoring & Observability

```
CloudWatch Logs
   ├─ /aws/lambda/insecure-api-demo-dev
   │  └─ Lambda execution logs
   │     ├─ Request/response details
   │     ├─ Errors and stack traces
   │     └─ Custom log messages
   │
   └─ /aws/apigateway/insecure-api-demo-dev
      └─ API Gateway access logs
         ├─ Request ID
         ├─ Source IP
         ├─ HTTP method & path
         ├─ Status code
         └─ Response size
```

## Resource Naming Convention

```
Pattern: {project_name}-{resource_type}-{environment}

Examples:
├─ Lambda: insecure-api-demo-dev
├─ API Gateway: insecure-api-demo-dev
├─ S3 Bucket: insecure-api-demo-frontend-dev-{account-id}
├─ IAM Role: insecure-api-demo-github-actions-dev
└─ Log Group: /aws/lambda/insecure-api-demo-dev
```

## Network Architecture

```
┌──────────────────────────────────────────────────────┐
│                    Internet                          │
└───────────────────┬──────────────────────────────────┘
                    │
                    │ HTTPS (443)
                    │
        ┌───────────┴──────────┐
        │                      │
        │                      │
        ↓                      ↓
┌──────────────┐      ┌──────────────┐
│ CloudFront   │      │ API Gateway  │
│ (Optional)   │      │  Regional    │
│              │      │  Endpoint    │
└──────┬───────┘      └──────┬───────┘
       │                     │
       │ HTTP (80)           │ Lambda Invoke
       │                     │
       ↓                     ↓
┌──────────────┐      ┌──────────────┐
│  S3 Bucket   │      │   Lambda     │
│   Website    │      │   Function   │
│   Hosting    │      │   (VPC N/A)  │
└──────────────┘      └──────────────┘

Note: No VPC required - all services are managed
```

## Summary

- **Serverless Architecture:** No EC2 instances to manage
- **Event-Driven:** API Gateway triggers Lambda on request
- **Stateless:** No persistent connections or sessions
- **Scalable:** Auto-scales with demand (within limits)
- **OIDC-Based:** Secure deployments without long-lived credentials
- **Infrastructure as Code:** Everything defined in Terraform
- **Educational Focus:** Intentionally vulnerable for learning

---

**For more details, see:**
- [README.md](../README.md) - Full documentation
- [DEPLOYMENT.md](../DEPLOYMENT.md) - Deployment guide
- [OIDC-CONFIGURATION.md](OIDC-CONFIGURATION.md) - OIDC setup
