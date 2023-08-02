
resource "aws_glue_catalog_database" "fund_data_raw_db" {
  name = "raw_antarctica_db"
}

resource "aws_glue_catalog_database" "fund_data_staging_db" {
  name = "staging_antarctica_db"
}

resource "aws_glue_catalog_database" "fund_data_processed_db" {
  name = "processed_antarctica_db"
}


data "aws_iam_policy_document" "fund_data_glue_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fund_data_glue_role" {
  name               = "fund_data_glue_role"
  assume_role_policy = data.aws_iam_policy_document.fund_data_glue_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

resource "aws_sqs_queue" "fund_data_queue" {
  for_each = var.data_source
  name     = "fund_data_${each.key}_queue"
}

data "aws_iam_policy_document" "fund_data_queue_policy" {
  for_each = var.data_source
  statement {
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    resources = [aws_sqs_queue.fund_data_queue[each.key].arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.fund_data_topic[each.key].arn]
    }
  }
}

resource "aws_sqs_queue_policy" "fund_data_queue_policy" {
  for_each  = var.data_source
  queue_url = aws_sqs_queue.fund_data_queue[each.key].id
  policy    = data.aws_iam_policy_document.fund_data_queue_policy[each.key].json
}

resource "aws_sns_topic_subscription" "fund_data_sqs_target" {
  for_each  = var.data_source
  topic_arn = aws_sns_topic.fund_data_topic[each.key].arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.fund_data_queue[each.key].arn
}

resource "aws_glue_crawler" "fund_data_crawler" {
  for_each      = var.data_source
  database_name = aws_glue_catalog_database.fund_data_raw_db.name
  name          = "fund_data_${each.key}_crawler"
  role          = aws_iam_role.fund_data_glue_role.arn
  s3_target {
    path            = "s3://${aws_s3_bucket.fund_data_bucket.bucket}/raw/${each.key}/"
    event_queue_arn = aws_sqs_queue.fund_data_queue[each.key].arn
  }
  recrawl_policy {
    recrawl_behavior = "CRAWL_EVENT_MODE"
  }
}

resource "aws_glue_job" "fund_data_cleaning_job" {
  for_each     = var.data_source
  name         = "fund_data_${each.key}_cleaning_job"
  glue_version = "3.0"
  role_arn     = aws_iam_role.fund_data_glue_role.arn
  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts_bucket.bucket}/cleaning/${each.value["glue_cleaning_script"]}"
    python_version  = "3"
  }

  default_arguments = {
    "--extra-py-files" : "s3://${aws_s3_bucket.glue_scripts_bucket.bucket}/glue_modules.zip",
    "--enable-continuous-cloudwatch-log" : "true"
  }
}

resource "aws_glue_trigger" "fund_cleaning_trigger" {
  for_each = var.data_source
  name     = "fund_data_${each.key}_cleaning_job_trigger"
  type     = "CONDITIONAL"

  actions {
    job_name = aws_glue_job.fund_data_cleaning_job[each.key].name
  }
  predicate {
    conditions {
      crawler_name = aws_glue_crawler.fund_data_crawler[each.key].name
      crawl_state  = "SUCCEEDED"
    }
  }
}
