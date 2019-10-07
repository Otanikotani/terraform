provider "aws" {
  profile = "default"
  region = "us-east-1"
}

output "hello_lambda" {
  value = aws_lambda_function.hello.id
}
output "bye_lambda" {
  value = aws_lambda_function.bye.id
}