output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = "${aws_api_gateway_stage.api.invoke_url}"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.api_lambda.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.api_lambda.arn
}

output "s3_website_url" {
  description = "S3 static website URL"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = aws_s3_bucket.frontend.id
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.api.id
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "deployment_instructions" {
  description = "Next steps after infrastructure deployment"
  value       = <<-EOT

    ✅ Infrastructure deployed successfully!

    Next step: Deploy the application code to Lambda

    Run one of these commands from the project root:

      Linux/Mac:   bash scripts/deploy-lambda.sh
      Windows:     .\scripts\deploy-lambda.ps1

    Or manually:
      npm install
      zip -r lambda.zip src/ package.json package-lock.json node_modules/
      aws lambda update-function-code --function-name ${aws_lambda_function.api_lambda.function_name} --zip-file fileb://lambda.zip

    📝 API Endpoints (use in frontend):
      Base URL: ${aws_api_gateway_stage.api.invoke_url}

      Example endpoints:
        ${aws_api_gateway_stage.api.invoke_url}/users
        ${aws_api_gateway_stage.api.invoke_url}/search?query=admin
        ${aws_api_gateway_stage.api.invoke_url}/admin/config

  EOT
}
