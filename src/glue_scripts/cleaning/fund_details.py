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

dyf = glueContext.create_dynamic_frame.from_catalog(database='raw_antarctica_db', table_name='fund_details')
df = dyf.toDF()
df = drop_duplicates(df)
date_fields = ['inception_date', 'returns_as_of_date']
for date_field in date_fields:
    df = cast_date_field(df, date_field, "dd/MM/yyyy")

sdyf = DynamicFrame.fromDF(df, glueContext, "staging_fund_details")
s3output = glueContext.getSink(
  path=f"s3://fund-data-{account_id}/staging/fund_details",
  connection_type="s3",
  updateBehavior="UPDATE_IN_DATABASE",
  partitionKeys=['year', 'month', 'day'],
  compression="snappy",
  enableUpdateCatalog=True,
)
s3output.setCatalogInfo(
  catalogDatabase="staging_antarctica_db", catalogTableName="fund_details"
)
s3output.setFormat("glueparquet")
s3output.writeFrame(sdyf)

job.commit()
