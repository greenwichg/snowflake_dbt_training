--------------------------------------------------------------------------------
-- Day 2 / Exercise 11 — Dynamic Tables vs Materialized Views
--                       (+ Iceberg tables overview)
--
--  Materialized View : auto-maintained result of a SINGLE-table query
--                      (no joins/unions; Enterprise edition). Snowflake keeps
--                      it fresh synchronously behind the scenes.
--  Dynamic Table     : declarative pipeline step — ANY query (joins, unions,
--                      window functions), refreshed incrementally on a
--                      TARGET_LAG you choose. Replaces many stream+task combos.
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE SCHEMA TRAINING_DB.ANALYTICS;

--------------------------------------------------------------------------------
-- 1. Materialized View — single-table aggregation only
--------------------------------------------------------------------------------
CREATE OR REPLACE MATERIALIZED VIEW ANALYTICS.MV_ORDERS_BY_STATUS AS
SELECT STATUS, COUNT(*) AS ORDER_COUNT, SUM(AMOUNT) AS TOTAL_AMOUNT
FROM TRAINING_DB.RAW.ORDERS
GROUP BY STATUS;

SELECT * FROM ANALYTICS.MV_ORDERS_BY_STATUS;

-- Try to materialize a JOIN — fails: MVs don't support multi-table queries.
-- CREATE MATERIALIZED VIEW ANALYTICS.MV_WONT_WORK AS
-- SELECT c.COUNTRY, SUM(o.AMOUNT)
-- FROM TRAINING_DB.RAW.ORDERS o JOIN TRAINING_DB.RAW.CUSTOMERS c USING (CUSTOMER_ID)
-- GROUP BY 1;

--------------------------------------------------------------------------------
-- 2. Dynamic Table — the same business question WITH the join
--------------------------------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_REVENUE_BY_COUNTRY
  TARGET_LAG = '1 minute'          -- "keep me at most 1 minute behind sources"
  WAREHOUSE  = TRAINING_WH
AS
SELECT
    c.COUNTRY,
    COUNT(o.ORDER_ID)  AS ORDERS,
    SUM(o.AMOUNT)      AS REVENUE
FROM TRAINING_DB.RAW.ORDERS o
JOIN TRAINING_DB.RAW.CUSTOMERS c ON c.CUSTOMER_ID = o.CUSTOMER_ID
WHERE o.STATUS = 'completed'
GROUP BY c.COUNTRY;

SELECT * FROM ANALYTICS.DT_REVENUE_BY_COUNTRY ORDER BY REVENUE DESC;

--------------------------------------------------------------------------------
-- 3. Watch both refresh automatically
--------------------------------------------------------------------------------
INSERT INTO TRAINING_DB.RAW.ORDERS VALUES
  (3001, 1, CURRENT_DATE, 'completed', 'USD', 999.00);

-- MV: reflects the change immediately (kept consistent at query time).
SELECT * FROM ANALYTICS.MV_ORDERS_BY_STATUS;

-- Dynamic table: wait ~1 minute (TARGET_LAG), then re-run:
SELECT * FROM ANALYTICS.DT_REVENUE_BY_COUNTRY ORDER BY REVENUE DESC;

-- Refresh history & lag monitoring:
SELECT name, state, refresh_action, refresh_trigger, data_timestamp
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY())
WHERE name = 'DT_REVENUE_BY_COUNTRY'
ORDER BY data_timestamp DESC LIMIT 10;

-- Chaining: a dynamic table can read other dynamic tables → a declarative DAG.
-- You state WHAT each step is and HOW fresh it must be; Snowflake schedules
-- the incremental refreshes. (Compare: Day 2 streams+tasks = imperative CDC.)

--------------------------------------------------------------------------------
-- 4. Decision guide
--------------------------------------------------------------------------------
--  Use a Materialized View when: single-table aggregate/projection, hot query,
--    need always-consistent results (e.g. pre-aggregating a huge raw table).
--  Use a Dynamic Table when: multi-table transformations, pipeline steps with
--    a freshness SLA, replacing stream+task plumbing.
--  Use dbt models (Days 3-5) when: you want version control, tests, docs and
--    code review around the transformation logic — dbt can even materialize
--    models AS dynamic tables.

--------------------------------------------------------------------------------
-- 5. Iceberg Tables — 5 minute overview (no hands-on: needs cloud bucket)
--------------------------------------------------------------------------------
-- Apache Iceberg = open table format: data as Parquet + metadata in YOUR
-- object storage, readable/writable by many engines (Spark, Trino, Snowflake).
--
-- CREATE ICEBERG TABLE ... CATALOG = 'SNOWFLAKE'
--   EXTERNAL_VOLUME = 'my_s3_volume' BASE_LOCATION = 'orders/';
--
-- Native table : Snowflake-managed storage, all features, best performance.
-- Iceberg table: your storage, open format, multi-engine access; trades some
--                features/perf for zero lock-in. Choose it when other engines
--                must read the same data without copies.

-- Clean up
DROP MATERIALIZED VIEW IF EXISTS ANALYTICS.MV_ORDERS_BY_STATUS;  -- MVs bill maintenance credits
DROP DYNAMIC TABLE     IF EXISTS ANALYTICS.DT_REVENUE_BY_COUNTRY;
DELETE FROM TRAINING_DB.RAW.ORDERS WHERE ORDER_ID = 3001;

-- Checkpoint:
--  * Why can't an MV contain a join, and what would you use instead?
--  * What does TARGET_LAG trade off against cost?
--  * When would an Iceberg table beat a native table?
