variable "rest_api_id" {
  description = "API Gateway REST API ID"
  type        = string
}

variable "resource_id" {
  description = "API Gateway Resource ID"
  type        = string
}

variable "http_method" {
  description = "HTTP method (GET, POST, PUT, etc.)"
  type        = string
}

variable "lambda_uri" {
  description = "Lambda function invoke ARN"
  type        = string
}
