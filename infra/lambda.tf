
data "archive_file" "lambda_src_code" {
  type        = "zip"
  source_dir  = "../src"
  excludes    = ["glue_scripts", "glue_modules"]
  output_path = "${path.module}/lambda_modules.zip"
}


data "aws_iam_policy_document" "copy_lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "copy_lambda_role" {
  name               = "copy_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.copy_lambda_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSLambdaExecute"
  ]
}


resource "aws_lambda_function" "copy_lambda" {
  for_each         = var.data_source
  filename         = "${path.module}/lambda_modules.zip"
  function_name    = "fund_data_${each.key}_copy_lambda"
  role             = aws_iam_role.copy_lambda_role.arn
  handler          = "lambda_modules.handlers.copy_s3_object_handler.handler"
  source_code_hash = data.archive_file.lambda_src_code.output_base64sha256
  runtime          = "python3.9"
  layers           = ["arn:aws:lambda:eu-west-1:017000801446:layer:AWSLambdaPowertoolsPythonV2:40"]
  timeout          = 60
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      source_bucket = each.value["source_bucket"]
      source_key    = each.value["source_key"]
      target_bucket = aws_s3_bucket.fund_data_bucket.id
      target_dir    = each.value["target_dir"]
    }
  }
}

resource "aws_iam_role" "crawler_lambda_role" {
  name               = "crawler_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.copy_lambda_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSLambdaExecute",
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]
}

resource "aws_sns_topic_subscription" "fund_data_lambda_target" {
  for_each  = var.data_source
  topic_arn = aws_sns_topic.fund_data_topic[each.key].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.crawler_lambda[each.key].arn
}

resource "aws_lambda_permission" "crawler_lambda_sns_permission" {
  for_each      = var.data_source
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crawler_lambda[each.key].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.fund_data_topic[each.key].arn
}


resource "aws_lambda_function" "crawler_lambda" {
  for_each         = var.data_source
  filename         = "${path.module}/lambda_modules.zip"
  function_name    = "fund_data_${each.key}_crawler_lambda"
  role             = aws_iam_role.crawler_lambda_role.arn
  handler          = "lambda_modules.handlers.start_glue_crawler_handler.handler"
  source_code_hash = data.archive_file.lambda_src_code.output_base64sha256
  runtime          = "python3.9"
  layers           = ["arn:aws:lambda:eu-west-1:017000801446:layer:AWSLambdaPowertoolsPythonV2:40"]
  timeout          = 60
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      crawler_name = aws_glue_crawler.fund_data_crawler[each.key].name
    }
  }
}