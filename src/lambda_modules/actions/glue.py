from aws_lambda_powertools import Logger

logger = Logger()


def start_glue_crawler(glue_client, crawler_name):
    resp = glue_client.start_crawler(
        Name=crawler_name
        )
    logger.info(f'Started Crawler: {crawler_name}')
