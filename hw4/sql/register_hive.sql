CREATE EXTERNAL TABLE IF NOT EXISTS hw4_events_agg (
    event_count BIGINT,
    total_value DOUBLE,
    avg_value DOUBLE
)
PARTITIONED BY (dt STRING)
STORED AS PARQUET
LOCATION 'hdfs://team-17-nn:9000/user/hive/warehouse/hw4_events_agg';

MSCK REPAIR TABLE hw4_events_agg;
SHOW PARTITIONS hw4_events_agg;
SELECT * FROM hw4_events_agg;
