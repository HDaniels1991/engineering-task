from awsglue.transforms import *
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from glue_modules.cleaning import drop_duplicates, cast_date_field
import boto3

sts = boto3.client("sts")
account_id = sts.get_caller_identity()["Account"]

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)

dyf = glueContext.create_dynamic_frame.from_catalog(database='raw_antarctica_db', table_name='fund_prices')
df = dyf.toDF()
df = drop_duplicates(df)
df = cast_date_field(df, 'price_date', "yyyy-MM-dd")

sdyf = DynamicFrame.fromDF(df, glueContext, "staging_fund_prices")
s3output = glueContext.getSink(
  path=f"s3://fund-data-{account_id}/staging/fund_prices",
  connection_type="s3",
  updateBehavior="UPDATE_IN_DATABASE",
  partitionKeys=['year', 'month', 'day'],
  compression="snappy",
  enableUpdateCatalog=True,
)
s3output.setCatalogInfo(
  catalogDatabase="staging_antarctica_db", catalogTableName="fund_prices"
)
s3output.setFormat("glueparquet")
s3output.writeFrame(sdyf)

job.commit()
