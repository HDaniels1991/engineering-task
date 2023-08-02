

data "aws_iam_policy_document" "fund_data_topic_policy" {
  for_each = var.data_source
  statement {
    actions = [
      "SNS:Publish"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    resources = [
      aws_sns_topic.fund_data_topic[each.key].arn
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        aws_s3_bucket.fund_data_bucket.arn
      ]
    }
  }
}

resource "aws_sns_topic_policy" "fund_data_topic_policy" {
  for_each = var.data_source
  arn      = aws_sns_topic.fund_data_topic[each.key].arn
  policy   = data.aws_iam_policy_document.fund_data_topic_policy[each.key].json
}


resource "aws_sns_topic" "fund_data_topic" {
  for_each = var.data_source
  name     = "fund_data_${each.key}_topic"
}

resource "aws_s3_bucket" "fund_data_bucket" {
  bucket = "fund-data-${local.account_id}"
}

resource "aws_s3_bucket_notification" "fund_data_bucket_notification" {
  bucket = aws_s3_bucket.fund_data_bucket.id

  topic {
    id            = "fund_data_fund_details_bucket_notification"
    topic_arn     = aws_sns_topic.fund_data_topic["fund_details"].arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.data_source["fund_details"]["target_dir"]
  }
  topic {
    id            = "fund_data_fund_prices_bucket_notification"
    topic_arn     = aws_sns_topic.fund_data_topic["fund_prices"].arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.data_source["fund_prices"]["target_dir"]
  }
}
