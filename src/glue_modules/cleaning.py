import pyspark.sql.functions as F


def drop_duplicates(df):
    """
    Drop duplicate records.
    """
    distinct_df = df.distinct()
    print(f'Dropping {df.count() - distinct_df.count()} duplicate records')
    return distinct_df


def cast_date_field(df, date_field, date_format):
    """
    Cast string field to date.
    """
    df = df.withColumn(date_field, F.to_date(F.col(date_field),date_format))
    return df
