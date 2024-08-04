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
  region = "${var.region}"

  s3_use_path_style = false
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true

  endpoints {
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

locals {
  layer_name = "moment-joi"
  layers_path = "${path.module}/../layers/${local.layer_name}/nodejs"
  lambda_name = "convert-date"
  lambda_path = "${path.module}/../lambdas/${local.lambda_name}/"
  runtime = "nodejs20.x"
}

resource "null_resource" "build_lambda_layers" {
  triggers = {
    layer_build = "${md5(file("${local.layers_path}"/package.json))}"
  }

  provisioner "local-exec" {
    working_dir = "${local.layers_path}"
    command = "npm install --production && cd ../ && zip -9 -r --quiet ${local.layer_name}.zip *"
  }
}

resource "aws_lambda_layer_version" "this" {
  filename = "${local.layers_path}/../${local.layer_name}.zip"
  layer_name = "${local.layer_name}"
  description = "joi: 14.3.1, moment: 2.24.0"

  compatible_runtimes = ["${local.runtime}"]

  depends_on = [ "null_resource.build_lambda_layers" ]
}

data "archive_file" "convert-date" {
  type = "zip"
  output_path = "${local.lambda_path}/${local.lambda_name}.zip"

  source {
    content = "${file("${local.lambda_path}/index.js")}"
    filename = "index.js"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_lambda_function" "convert-date" {
  function_name = "${local.lambda_name}"
  handler = "index.handler"
  runtime = "${local.runtime}"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  layers = ["${aws_lambda_layer_version.this.arn}"]

  filename = "${data.archive_file.convert-date.output_path}"
  source_code_hash = "${data.archive_file.convert-date.output_base64sha256}"

  timeout = 30
  memory_size = 128
}