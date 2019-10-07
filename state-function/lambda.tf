# Bucket for the lambda, example.zip has the lambda code, and lambda
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "examplestatemachine"

  tags = {
    Name = "Example State machine lambdas"
  }
}

data "archive_file" "hello_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/hello.zip"
  source_file  = "${path.module}/hello.js"
}

data "archive_file" "bye_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/bye.zip"
  source_file  = "${path.module}/bye.js"
}

resource "aws_s3_bucket_object" "hello_lambda_bucket_object" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key = "hello.zip"
  source = data.archive_file.hello_lambda_zip.output_path
}

resource "aws_s3_bucket_object" "bye_lambda_bucket_object" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key = "bye.zip"
  source = data.archive_file.bye_lambda_zip.output_path
}

resource "aws_lambda_function" "hello" {
  function_name = "HelloExample"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = aws_s3_bucket_object.hello_lambda_bucket_object.key

  handler = "hello.handler"
  runtime = "nodejs10.x"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_function" "bye" {
  function_name = "ByeExample"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = aws_s3_bucket_object.bye_lambda_bucket_object.key

  handler = "bye.handler"
  runtime = "nodejs10.x"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.lambda_exec.arn

  definition = <<EOF
{
  "Comment": "A Hello World example of the Amazon States Language using an AWS Lambda Function",
  "StartAt": "HelloWorld",
  "States": {
    "HelloWorld": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.hello.arn}",
      "Next": "Is It Time To Say GoodBye"
    },
    "Is It Time To Say GoodBye": {
            "Type" : "Choice",
            "Choices": [
              {
                "Variable": "$.Status",
                "NumericEquals": 1,
                "Next": "GoodBye"
              },
              {
                "Variable": "$.Status",
                "NumericEquals": 0,
                "Next": "AnotherOne"
              }
          ]
    },
    "AnotherOne": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.hello.arn}",
      "End": true
    },
    "GoodBye": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.bye.arn}",
      "End": true
    }
  }
}
EOF
}