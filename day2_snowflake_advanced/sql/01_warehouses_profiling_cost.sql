--------------------------------------------------------------------------------
-- Day 2 / Exercise 6 — Warehouses & caching, micro-partitions & clustering,
--                      query profiling & cost optimization
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
USE SCHEMA TRAINING_DB.RAW;

--------------------------------------------------------------------------------
-- PART A — Multi-size warehouses: scale UP vs scale OUT
--------------------------------------------------------------------------------
-- Create warehouses of different sizes to compare
CREATE WAREHOUSE IF NOT EXISTS WH_XS WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 INITIALLY_SUSPENDED = TRUE;
CREATE WAREHOUSE IF NOT EXISTS WH_S  WAREHOUSE_SIZE = 'SMALL'  AUTO_SUSPEND = 60 INITIALLY_SUSPENDED = TRUE;
CREATE WAREHOUSE IF NOT EXISTS WH_M  WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 60 INITIALLY_SUSPENDED = TRUE;

-- Run the SAME heavy query on each size and compare durations in Query History.
-- (Each size up doubles the credits/hour AND roughly doubles the compute.)
USE WAREHOUSE WH_XS;
SELECT l_returnflag, l_linestatus, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM snowflake_sample_data.tpch_sf10.lineitem
GROUP BY 1, 2;

USE WAREHOUSE WH_S;
SELECT l_returnflag, l_linestatus, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM snowflake_sample_data.tpch_sf10.lineitem
GROUP BY 1, 2;

USE WAREHOUSE WH_M;
SELECT l_returnflag, l_linestatus, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM snowflake_sample_data.tpch_sf10.lineitem
GROUP BY 1, 2;

-- Scale UP   = bigger cluster  → one big query finishes faster.
-- Scale OUT  = more clusters   → many concurrent queries don't queue:
ALTER WAREHOUSE WH_XS SET MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 3 SCALING_POLICY = 'STANDARD';

--------------------------------------------------------------------------------
-- PART B — The three caches
--------------------------------------------------------------------------------
USE WAREHOUSE WH_XS;

-- Run 1: cold read from remote storage
SELECT l_returnflag, SUM(l_extendedprice) FROM snowflake_sample_data.tpch_sf10.lineitem GROUP BY 1;

-- Run 2: identical text → RESULT CACHE (Cloud Services layer), ~0 ms, no
-- warehouse needed. Query History shows "Query Result Reuse".
SELECT l_returnflag, SUM(l_extendedprice) FROM snowflake_sample_data.tpch_sf10.lineitem GROUP BY 1;

-- Run 3: different aggregation → result cache miss, but the WAREHOUSE CACHE
-- (local SSD of the running cluster) still avoids remote reads. In the Query
-- Profile, compare "Percentage scanned from cache".
SELECT l_returnflag, AVG(l_extendedprice) FROM snowflake_sample_data.tpch_sf10.lineitem GROUP BY 1;

-- Metadata cache: COUNT/MIN/MAX can be answered from micro-partition
-- metadata alone — no warehouse, even when suspended:
ALTER WAREHOUSE WH_XS SUSPEND;
SELECT COUNT(*) FROM snowflake_sample_data.tpch_sf10.lineitem;   -- instant, warehouse stays suspended

--------------------------------------------------------------------------------
-- PART C — Micro-partitions & clustering
--------------------------------------------------------------------------------
-- Every table is stored as immutable ~16MB columnar micro-partitions; Snowflake
-- keeps min/max per column per partition and PRUNES partitions that can't match.

-- See pruning in action: filter on a column the data is naturally ordered by.
USE WAREHOUSE WH_XS;
SELECT COUNT(*), SUM(o_totalprice)
FROM snowflake_sample_data.tpch_sf10.orders
WHERE o_orderdate BETWEEN '1995-01-01' AND '1995-01-31';
-- → open the Query Profile: "Partitions scanned" vs "Partitions total".

-- How well is a table clustered for a given key?
SELECT SYSTEM$CLUSTERING_INFORMATION('snowflake_sample_data.tpch_sf10.orders', '(o_orderdate)');

-- A clustering key tells Snowflake to maintain physical co-location (background
-- reclustering, costs credits). Only worth it for very large (multi-TB) tables
-- with selective filters on the key:
--   ALTER TABLE big_events CLUSTER BY (event_date);
-- For our small training tables: natural load order is more than enough.

--------------------------------------------------------------------------------
-- PART D — Query profiling & cost optimization
--------------------------------------------------------------------------------
-- Open: Monitoring → Query History → pick the PART A medium-warehouse query
-- → Query Profile tab. Find:
--   1. The most expensive operator (usually TableScan or Aggregate)
--   2. Partitions scanned vs total (pruning effectiveness)
--   3. "Bytes spilled to local/remote storage" → warehouse too small
--   4. Exploding joins (output rows >> input rows) → check join keys

-- Where do credits go? (ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;
SELECT warehouse_name, SUM(credits_used) AS credits
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time > DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY 1 ORDER BY 2 DESC;

-- Most expensive queries of the week:
SELECT query_text, warehouse_name, total_elapsed_time/1000 AS seconds,
       bytes_spilled_to_remote_storage, partitions_scanned, partitions_total
FROM snowflake.account_usage.query_history
WHERE start_time > DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY total_elapsed_time DESC
LIMIT 10;

-- Guardrail: a resource monitor that suspends warehouses at a credit quota
CREATE RESOURCE MONITOR IF NOT EXISTS TRAINING_MONITOR
  WITH CREDIT_QUOTA = 20 FREQUENCY = WEEKLY START_TIMESTAMP = IMMEDIATELY
  TRIGGERS ON 80 PERCENT DO NOTIFY
           ON 100 PERCENT DO SUSPEND;
ALTER WAREHOUSE TRAINING_WH SET RESOURCE_MONITOR = TRAINING_MONITOR;

-- Cost golden rules:
--  * AUTO_SUSPEND low (60s); never leave warehouses running
--  * Start XS, size up only when the profile shows spilling
--  * Separate warehouses per workload (load / transform / BI) for isolation
--  * Let the result cache work: identical query text, stable underlying data

--------------------------------------------------------------------------------
-- Clean up the experiment warehouses
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
DROP WAREHOUSE IF EXISTS WH_S;
DROP WAREHOUSE IF EXISTS WH_M;
DROP WAREHOUSE IF EXISTS WH_XS;
USE WAREHOUSE TRAINING_WH;

-- Checkpoint:
--  * Which cache lives in which architecture layer?
--  * Your query spills to remote storage — scale up or scale out?
--  * Why is clustering pointless on a 30-row ORDERS table?
