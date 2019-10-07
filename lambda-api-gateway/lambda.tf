# Bucket for the lambda, example.zip has the lambda code, and lambda
resource "aws_s3_bucket" "example_lambda_bucket" {
  bucket = "exampleapigatewaylambdasources"

  tags = {
    Name = "Example API Gateway Lamba source code"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_file  = "${path.module}/main.js"
}

resource "aws_s3_bucket_object" "example_lambda_bucket_object" {
  bucket = aws_s3_bucket.example_lambda_bucket.id
  key = "example.zip"
  source = data.archive_file.lambda_zip.output_path
}

resource "aws_lambda_function" "hello" {
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
  function_name = aws_lambda_function.hello.function_name
  principal = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}
