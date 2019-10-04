provider "aws" {
  profile = "default"
  region = "us-east-1"
}

# Bucket for the lambda, example.zip has the lambda code, and lambda
resource "aws_s3_bucket" "example_lambda_bucket" {
  bucket = "exampleapigatewaylambdasources"

  tags = {
    Name = "Example API Gateway Lamba source code"
  }
}

resource "aws_s3_bucket_object" "example_lambda_bucket_object" {
  bucket = aws_s3_bucket.example_lambda_bucket.id
  key = "example.zip"
  source = "example.zip"
}

resource "aws_lambda_function" "example" {
  function_name = "ServerlessExample"

  s3_bucket = aws_s3_bucket.example_lambda_bucket.id
  s3_key = aws_s3_bucket_object.example_lambda_bucket_object.key

  handler = "main.handler"
  runtime = "nodejs10.x"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}
# -------------------------------------------------------------------

# API Gateway
resource "aws_api_gateway_rest_api" "example" {
  name = "ServerlessExample"
  description = "Serverless API Gateway"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  parent_id = aws_api_gateway_rest_api.example.root_resource_id
  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.example.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_rest_api.example.root_resource_id
  http_method = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.example.invoke_arn
}

resource "aws_api_gateway_deployment" "example" {
  depends_on = [
    "aws_api_gateway_integration.lambda"
  ]

  rest_api_id = aws_api_gateway_rest_api.example.id
  stage_name = "test"
}
# -------------------------------------------------------------------

output "base_url" {
  value = aws_api_gateway_deployment.example.invoke_url
}