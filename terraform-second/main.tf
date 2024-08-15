terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.35.0"
    }
  }
}

provider "aws" {
  access_key = "test"
  secret_key = "test"
  region = var.region

  endpoints {
    cloudwatch     = "http://localhost:4566"
    iam            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
  }
}

locals {
  layer_name = "moment-joi-second"
  layers_path = "${path.module}/../layers/moment-joi/nodejs"
  lambda_name = "convert-date-second"
  lambda_path = "${path.module}/../lambdas/convert-date/"
  runtime = "nodejs20.x"
}

resource "null_resource" "build_lambda_layers_second" {
  triggers = {
    layer_build = md5(file("${local.layers_path}/package.json"))
  }

  provisioner "local-exec" {
    working_dir = local.layers_path
    command = "npm install --production && cd ../ && zip -9 -r --quiet moment-joi.zip *"
  }
}

resource "aws_lambda_layer_version" "this_second" {
  filename = "${local.layers_path}/../moment-joi.zip"
  layer_name = local.layer_name
  description = "joi: 14.3.1, moment: 2.24.0"

  compatible_runtimes = [local.runtime]

  depends_on = [ null_resource.build_lambda_layers_second ]
}

data "archive_file" "convert-date_second" {
  type = "zip"
  output_path = "${local.lambda_path}/${local.lambda_name}.zip"

  source {
    content = file("${local.lambda_path}/index.js")
    filename = "index.js"
  }
}

resource "aws_iam_role" "iam_for_lambda_second" {
  name = "iam_for_lambda_second"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_function" "convert-date-second" {
  function_name = local.lambda_name
  handler = "index.handler"
  runtime = local.runtime
  role = aws_iam_role.iam_for_lambda_second.arn
  layers = [aws_lambda_layer_version.this_second.arn]

  filename = data.archive_file.convert-date_second.output_path
  source_code_hash = data.archive_file.convert-date_second.output_base64sha256

  timeout = 30
  memory_size = 128
}

resource "aws_cloudwatch_event_rule" "profile_generator_lambda_event_rule_second" {
  name = "profile-generator-lambda-event-rule-fix"
  description = "execute only every day at 00 BRT 15 min"
  schedule_expression = "cron(0 12 ? * * *)"
}

resource "aws_cloudwatch_event_target" "profile_generator_lambda_target_second" {
  arn  = aws_lambda_function.convert-date-second.arn
  rule = aws_cloudwatch_event_rule.profile_generator_lambda_event_rule_second.name
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_function_second" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.convert-date-second.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.profile_generator_lambda_event_rule_second.arn
}