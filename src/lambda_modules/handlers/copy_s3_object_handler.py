import os
import boto3
from datetime import datetime
from aws_lambda_powertools import Logger, Tracer
from lambda_modules.actions.s3 import copy_s3_object

tracer = Tracer()
logger = Logger()
s3_client = boto3.client('s3')


source_bucket = os.environ.get('source_bucket')
source_key = os.environ.get('source_key')
target_bucket = os.environ.get('target_bucket')
target_dir = os.environ.get('target_dir')
path = datetime.today().strftime('year=%Y/month=%m/day=%d')
target_key = f'{target_dir}/{path}/data.csv'


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def handler(event, context):
    '''
    Lambda handler which copies S3 object into the Antarctica data lake.
    '''
    copy_s3_object(s3_client, source_bucket, source_key, target_bucket, target_key)
