# Migration to API Gateway HTTP API

## What Changed

The project has been migrated from **API Gateway REST API** to **API Gateway HTTP API (v2)** for better performance, lower cost, and simpler configuration.

## Benefits of HTTP API

### 💰 **Lower Cost**
- **70% cheaper** than REST API
- $1.00 per million requests (vs $3.50 for REST API)

### ⚡ **Better Performance**
- Lower latency
- Faster cold starts
- More efficient routing

### 🎯 **Simpler Configuration**
- No need to create individual resources and methods
- Single catch-all route forwards everything to Lambda
- Automatic CORS configuration
- Auto-deployment enabled

## Technical Changes

### Terraform Configuration

**Before (REST API):**
```hcl
resource "aws_api_gateway_rest_api" "api" { ... }
resource "aws_api_gateway_resource" "users" { ... }
resource "aws_api_gateway_method" "users_get" { ... }
resource "aws_api_gateway_integration" "users_get" { ... }
# ... repeated for every endpoint
resource "aws_api_gateway_deployment" "api" { ... }
resource "aws_api_gateway_stage" "api" { ... }
```

**After (HTTP API):**
```hcl
resource "aws_apigatewayv2_api" "api" {
  name          = "insecure-api-demo-dev"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_uri    = aws_lambda_function.api_lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "catch_all" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "dev"
  auto_deploy = true
}
```

### Lambda Handler Updates

The Lambda function now supports **both** payload formats for backward compatibility:

**Payload Format Detection:**
```javascript
const isV2 = event.version === '2.0' || event.requestContext?.http;
```

**Event Normalization:**
```javascript
const path = isV2 ? event.rawPath : event.path;
const method = isV2 ? event.requestContext.http.method : event.httpMethod;
```

### Removed Components

The following modules are **no longer needed**:
- ❌ `terraform/modules/api_method/` - Not needed with catch-all route
- ❌ `terraform/modules/api_cors/` - CORS handled at API level

### URL Format

**No change to URL format:**
```
https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/{endpoint}
```

Example:
```
https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/users
```

## Migration Steps

If you have an existing REST API deployment:

### 1. Destroy Old REST API (if exists)

```bash
cd terraform

# List current resources
terraform state list | grep aws_api_gateway

# Remove REST API resources from state
terraform state rm 'aws_api_gateway_rest_api.api'
terraform state rm 'aws_api_gateway_deployment.api'
terraform state rm 'aws_api_gateway_stage.api'
# ... remove all REST API resources
```

Or simply destroy and recreate:
```bash
terraform destroy
terraform apply
```

### 2. Update Lambda Code

The Lambda handler has been updated to support both formats, but you should redeploy:

```bash
cd ..
.\scripts\deploy-lambda.ps1   # Windows
# OR
bash scripts/deploy-lambda.sh  # Linux/Mac
```

### 3. Update GitHub Secrets

The `API_GATEWAY_ID` will change to the new HTTP API ID. Update your GitHub secret with the new value from:

```bash
terraform output api_gateway_id
```

### 4. Test All Endpoints

```bash
API_URL=$(terraform output -raw api_gateway_url)

# Test endpoints
curl $API_URL/users
curl "$API_URL/search?query=admin"
curl $API_URL/admin/config
```

## Comparison Table

| Feature | REST API | HTTP API |
|---------|----------|----------|
| **Cost** | $3.50/million requests | $1.00/million requests |
| **Latency** | Higher | Lower |
| **Configuration** | Complex (resources, methods, integrations) | Simple (routes) |
| **CORS** | Manual per method | Automatic at API level |
| **Payload Format** | v1.0 | v2.0 (faster, JSON) |
| **Auto Deploy** | Manual | Automatic |
| **WebSocket Support** | ❌ No | ✅ Yes |
| **Private Integrations** | ✅ Yes | ✅ Yes |
| **API Keys** | ✅ Yes | ❌ No (use Lambda authorizers) |
| **Usage Plans** | ✅ Yes | ❌ No |
| **Request Validation** | ✅ Yes | ❌ No |

## What Stays the Same

✅ Lambda function code (backward compatible)
✅ All endpoints and paths
✅ Response formats
✅ CORS headers
✅ Frontend application
✅ Security vulnerabilities (intentional)
✅ CloudWatch logging
✅ GitHub Actions workflow

## Troubleshooting

### Issue: 404 Not Found

**Solution:** HTTP API uses `rawPath` instead of `path`. Make sure Lambda code is updated.

### Issue: CORS errors

**Solution:** CORS is now configured at the API level. Check:
```hcl
cors_configuration {
  allow_origins = ["*"]
  allow_methods = ["*"]
  allow_headers = ["*"]
}
```

### Issue: Event structure errors

**Solution:** The Lambda handler now normalizes both v1 and v2 formats. Make sure you've deployed the updated code.

## Performance Improvements

Expected improvements after migration:

- 📉 **~30% lower latency** on average
- 💰 **70% cost reduction** for API Gateway
- ⚡ **Faster deployments** with auto-deploy
- 🎯 **Simpler maintenance** with fewer resources

## References

- [AWS HTTP API Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [REST API vs HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-vs-rest.html)
- [HTTP API Payload Format](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html)

---

**Migration completed!** Your API is now running on the faster, cheaper HTTP API protocol.
