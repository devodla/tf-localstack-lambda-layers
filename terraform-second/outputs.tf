output "layer_arn" {
  value = aws_lambda_layer_version.this_second.arn
}

output "layer_created_at" {
  value = aws_lambda_layer_version.this_second.created_date
}

output "layer_version" {
  value = aws_lambda_layer_version.this_second.version
}

output "layer_size" {
  value = aws_lambda_layer_version.this_second.source_code_size
}

output "lambda_arn" {
  value = aws_lambda_function.convert-date-second.invoke_arn
}

output "lambda_size" {
  value = aws_lambda_function.convert-date-second.source_code_size
}

output "lambda_updated_at" {
  value = aws_lambda_function.convert-date-second.last_modified
}