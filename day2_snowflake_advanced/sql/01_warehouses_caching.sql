--------------------------------------------------------------------------------
-- Day 2 / Exercise 1 — Warehouses, scaling & caching
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
USE SCHEMA TRAINING_DB.RAW;

-- Scale UP (bigger cluster: faster single big query) vs
-- scale OUT (more clusters: higher concurrency).
ALTER WAREHOUSE TRAINING_WH SET WAREHOUSE_SIZE = 'SMALL';
ALTER WAREHOUSE TRAINING_WH SET WAREHOUSE_SIZE = 'XSMALL';  -- back down

-- Multi-cluster (Enterprise edition): handles concurrency spikes
ALTER WAREHOUSE TRAINING_WH SET
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 2
  SCALING_POLICY    = 'STANDARD';

--------------------------------------------------------------------------------
-- Caching experiment (use a big sample table so timings are visible)
--------------------------------------------------------------------------------
USE WAREHOUSE TRAINING_WH;

-- Run 1: cold — reads from remote storage
SELECT l_returnflag, SUM(l_extendedprice) AS revenue
FROM snowflake_sample_data.tpch_sf10.lineitem
GROUP BY 1;

-- Run 2: identical query — served from the RESULT CACHE (Cloud Services),
-- ~instant, uses NO warehouse compute. Check Query History: "Query Result Reuse".
SELECT l_returnflag, SUM(l_extendedprice) AS revenue
FROM snowflake_sample_data.tpch_sf10.lineitem
GROUP BY 1;

-- Run 3: slightly different query — result cache misses, but the WAREHOUSE
-- CACHE (local SSD) still helps. Compare "Bytes scanned from cache" in the
-- Query Profile.
SELECT l_returnflag, AVG(l_extendedprice) AS avg_price
FROM snowflake_sample_data.tpch_sf10.lineitem
GROUP BY 1;

-- Suspending the warehouse drops its local cache (result cache survives):
ALTER WAREHOUSE TRAINING_WH SUSPEND;
ALTER WAREHOUSE TRAINING_WH RESUME;

--------------------------------------------------------------------------------
-- Read a Query Profile: Monitoring → Query History → pick the cold run →
-- "Query Profile". Find: pruning (partitions scanned vs total), the most
-- expensive operator, and whether anything spilled to disk.
--------------------------------------------------------------------------------

-- Checkpoint:
--  * Which cache lives in which architecture layer?
--  * Your dashboard has 50 concurrent users running small queries. Scale up
--    or scale out? Why?
