
resource "aws_s3_bucket" "glue_scripts_bucket" {
  bucket = "glue-scripts-${local.account_id}"
}

data "archive_file" "glue_src_code" {
  type        = "zip"
  source_dir  = "../src"
  excludes    = ["lambda_modules", "glue_scripts"]
  output_path = "${path.module}/glue_modules.zip"
}

resource "aws_s3_object" "s3_glue_modules" {
  bucket = aws_s3_bucket.glue_scripts_bucket.id
  key    = "glue_modules.zip"
  source = "${path.module}/glue_modules.zip"
  etag   = filemd5("${path.module}/glue_modules.zip")
}

resource "aws_s3_object" "s3_glue_cleaning_scripts" {
  for_each = var.data_source
  bucket   = aws_s3_bucket.glue_scripts_bucket.id
  key      = "cleaning/${each.value["glue_cleaning_script"]}"
  source   = "../src/glue_scripts/cleaning/${each.value["glue_cleaning_script"]}"
  etag     = filemd5("../src/glue_scripts/cleaning/${each.value["glue_cleaning_script"]}")
}
