
--------------------------------------------------------------------------------------------------------------
-- A. Create the bronze streaming table from the raw JSON files in your source volume
--------------------------------------------------------------------------------------------------------------
CREATE OR REFRESH STREAMING TABLE sdp_1_bronze.orders_bronze_demo05
AS
SELECT
  *,
  current_timestamp() AS processing_time,   -- Records when each row was ingested
  _metadata.file_name AS source_file        -- Captures the source file name for lineage
FROM STREAM read_files(                      -- Performs incremental ingestion with checkpoints using Auto Loader
    "${source}/orders",                      -- Uses the 'source' configuration parameter set in the pipeline settings
    format => 'JSON'
);

--------------------------------------------------------------------------------------------------------------
-- B. Create the silver streaming table from the bronze streaming table
--------------------------------------------------------------------------------------------------------------
CREATE OR REFRESH STREAMING TABLE sdp_2_silver.orders_silver_demo05
AS
SELECT
  order_id,
  timestamp(order_timestamp) AS order_timestamp,   -- Casts the order_timestamp to a TIMESTAMP type
  customer_id,
  notifications
FROM STREAM sdp_1_bronze.orders_bronze_demo05;      -- Incrementally reads from the bronze streaming table

--------------------------------------------------------------------------------------------------------------
-- C. Create the gold materialized view aggregating the silver table by order date
--------------------------------------------------------------------------------------------------------------
CREATE OR REFRESH MATERIALIZED VIEW sdp_3_gold.gold_orders_by_date_demo05
AS
SELECT
  date(order_timestamp) AS order_date,
  count(*) AS total_daily_orders
FROM sdp_2_silver.orders_silver_demo05   -- Aggregates the full silver table with optimizations where applicable
GROUP BY date(order_timestamp);
