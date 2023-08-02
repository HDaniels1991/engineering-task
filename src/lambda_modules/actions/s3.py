from aws_lambda_powertools import Logger

logger = Logger()


def copy_s3_object(s3_client, source_bucket, source_key, target_bucket, target_key):
    resp = s3_client.copy_object(
        Bucket=target_bucket,
        Key=target_key,
        CopySource={'Bucket': source_bucket, 'Key': source_key})
    logger.info(f'Copied: s3://{source_bucket}/{source_key} to s3://{target_bucket}/{target_key}')
