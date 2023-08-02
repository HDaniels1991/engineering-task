import os
import boto3
from aws_lambda_powertools import Logger, Tracer
from lambda_modules.actions.glue import start_glue_crawler


tracer = Tracer()
logger = Logger()

region = os.environ.get('AWS_REGION')
crawler_name = os.environ.get('crawler_name')
glue_client = boto3.client('glue', region_name=region)


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def handler(event, context):
    '''
    Lambda handler which starts a glue crawler.
    '''
    start_glue_crawler(glue_client, crawler_name)
