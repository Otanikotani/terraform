provider "aws" {
  profile = "default"
  region = "us-east-1"
}

output "base_url" {
  value = aws_api_gateway_deployment.example.invoke_url
}