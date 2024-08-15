# tf-localstack-lambda-layers
For created in localstack using version pro wih hobby license.

## First deployment

    aws events list-rules

```json
{
  "Rules": [
    {
      "Name": "profile-generator-lambda-event-rule",
      "Arn": "arn:aws:events:sa-east-1:000000000000:rule/profile-generator-lambda-event-rule",
      "State": "ENABLED",
      "Description": "execute only every day at 00 BRT 15 min",
      "ScheduleExpression": "cron(15 03 ? * * *)",
      "EventBusName": "default"
    }
  ]
}
```
    aws events list-targets-by-rule --rule "profile-generator-lambda-event-rule"

```json
{
    "Targets": [
        {
            "Id": "terraform-20240815210615340900000001",
            "Arn": "arn:aws:lambda:sa-east-1:000000000000:function:convert-date"
        }
    ]
}
```

## After next terraform apply with same name rule 
    
    aws events list-rules

```json
{
    "Rules": [
        {
            "Name": "profile-generator-lambda-event-rule",
            "Arn": "arn:aws:events:sa-east-1:000000000000:rule/profile-generator-lambda-event-rule",
            "State": "ENABLED",
            "Description": "execute only every day at 00 BRT 15 min",
            "ScheduleExpression": "cron(0 12 ? * * *)",
            "EventBusName": "default"
        }
    ]
}
```
    aws events list-targets-by-rule --rule "profile-generator-lambda-event-rule"

```json
{
  "Targets": [
    {
      "Id": "terraform-20240815210615340900000001",
      "Arn": "arn:aws:lambda:sa-east-1:000000000000:function:convert-date"
    },
    {
      "Id": "terraform-20240815210820393900000001",
      "Arn": "arn:aws:lambda:sa-east-1:000000000000:function:convert-date-second"
    }
  ]
}
```

# Solution!!

## Remove a target of first deploy

    aws events remove-targets --rule "profile-generator-lambda-event-rule" --ids "terraform-20240815210615340900000001"

```json
{
    "FailedEntryCount": 0,
    "FailedEntries": []
}
```

### Only 1 target for second deploy terraform

    aws events list-targets-by-rule --rule "profile-generator-lambda-event-rule"

```json
{
    "Targets": [
        {
            "Id": "terraform-20240815210820393900000001",
            "Arn": "arn:aws:lambda:sa-east-1:000000000000:function:convert-date-second"
        }
    ]
}
```

After change name of second deploy terraform and after execute: terraform plan

```terraform
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # aws_cloudwatch_event_rule.profile_generator_lambda_event_rule_second must be replaced
-/+ resource "aws_cloudwatch_event_rule" "profile_generator_lambda_event_rule_second" {
      ~ arn                 = "arn:aws:events:sa-east-1:000000000000:rule/profile-generator-lambda-event-rule" -> (known after apply)
      ~ id                  = "profile-generator-lambda-event-rule" -> (known after apply)
      - is_enabled          = true -> null
      ~ name                = "profile-generator-lambda-event-rule" -> "profile-generator-lambda-event-rule-fix" # forces replacement
      + name_prefix         = (known after apply)
      - state               = "ENABLED" -> null
      - tags                = {} -> null
      ~ tags_all            = {} -> (known after apply)
        # (4 unchanged attributes hidden)
    }

  # aws_cloudwatch_event_target.profile_generator_lambda_target_second must be replaced
-/+ resource "aws_cloudwatch_event_target" "profile_generator_lambda_target_second" {
      ~ id             = "profile-generator-lambda-event-rule-terraform-20240815210820393900000001" -> (known after apply)
      ~ rule           = "profile-generator-lambda-event-rule" -> "profile-generator-lambda-event-rule-fix" # forces replacement
      ~ target_id      = "terraform-20240815210820393900000001" -> (known after apply)
        # (5 unchanged attributes hidden)
    }

  # aws_lambda_permission.allow_cloudwatch_to_call_function_second must be replaced
-/+ resource "aws_lambda_permission" "allow_cloudwatch_to_call_function_second" {
      ~ id                  = "AllowExecutionFromCloudWatch" -> (known after apply)
      ~ source_arn          = "arn:aws:events:sa-east-1:000000000000:rule/profile-generator-lambda-event-rule" # forces replacement -> (known after apply) # forces replacement
      + statement_id_prefix = (known after apply)
        # (5 unchanged attributes hidden)
    }

Plan: 3 to add, 0 to change, 3 to destroy.

Apply complete! Resources: 3 added, 0 changed, 3 destroyed.
```

## After executing the terraform in first deploy

```terraform
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # aws_cloudwatch_event_rule.profile_generator_lambda_event_rule will be created
  + resource "aws_cloudwatch_event_rule" "profile_generator_lambda_event_rule" {
      + arn                 = (known after apply)
      + description         = "execute only every day at 00 BRT 15 min"
      + event_bus_name      = "default"
      + id                  = (known after apply)
      + name                = "profile-generator-lambda-event-rule"
      + name_prefix         = (known after apply)
      + schedule_expression = "cron(15 03 ? * * *)"
      + tags_all            = (known after apply)
    }

  # aws_cloudwatch_event_target.profile_generator_lambda_target will be created
  + resource "aws_cloudwatch_event_target" "profile_generator_lambda_target" {
      + arn            = "arn:aws:lambda:sa-east-1:000000000000:function:convert-date"
      + event_bus_name = "default"
      + id             = (known after apply)
      + rule           = "profile-generator-lambda-event-rule"
      + target_id      = (known after apply)
    }

  # aws_lambda_permission.allow_cloudwatch_to_call_function must be replaced
-/+ resource "aws_lambda_permission" "allow_cloudwatch_to_call_function" {
      ~ id                  = "AllowExecutionFromCloudWatch" -> (known after apply)
      ~ source_arn          = "arn:aws:events:sa-east-1:000000000000:rule/profile-generator-lambda-event-rule" # forces replacement -> (known after apply) # forces replacement
      + statement_id_prefix = (known after apply)
        # (5 unchanged attributes hidden)
    }

Plan: 3 to add, 0 to change, 1 to destroy.

Apply complete! Resources: 3 added, 0 changed, 1 destroyed.
```

## After 2 deploys i have separated 2 rules with every rule with 1 target

    aws events list-rules

```json
{
    "Rules": [
        {
            "Name": "profile-generator-lambda-event-rule-fix",
            "Arn": "arn:aws:events:sa-east-1:000000000000:rule/profile-generator-lambda-event-rule-fix",
            "State": "ENABLED",
            "Description": "execute only every day at 00 BRT 15 min",
            "ScheduleExpression": "cron(0 12 ? * * *)",
            "EventBusName": "default"
        },
        {
            "Name": "profile-generator-lambda-event-rule",
            "Arn": "arn:aws:events:sa-east-1:000000000000:rule/profile-generator-lambda-event-rule",
            "State": "ENABLED",
            "Description": "execute only every day at 00 BRT 15 min",
            "ScheduleExpression": "cron(15 03 ? * * *)",
            "EventBusName": "default"
        }
    ]
}
```
    aws events list-targets-by-rule --rule "profile-generator-lambda-event-rule"

```json
{
    "Targets": [
        {
            "Id": "terraform-20240815211332639000000001",
            "Arn": "arn:aws:lambda:sa-east-1:000000000000:function:convert-date"
        }
    ]
}
```

    aws events list-targets-by-rule --rule "profile-generator-lambda-event-rule-fix"

```json
{
    "Targets": [
        {
            "Id": "terraform-20240815211153190100000001",
            "Arn": "arn:aws:lambda:sa-east-1:000000000000:function:convert-date-second"
        }
    ]
}
```
