# IAM role which dictates what other AWS services the Lambda function
# may access.
# It is not important what is here as long as it is not about security
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_example"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}


data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    sid = ""

    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "states.us-east-1.amazonaws.com",
        "events.amazonaws.com"

      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role_policy" "lambda-execution" {
  name        = "tf-${terraform.workspace}-lambda-execution"
  role   = aws_iam_role.lambda_exec.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeFunction",
        "states:StartExecution"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
