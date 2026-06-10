--------------------------------------------------------------------------------
-- Day 2 / Exercise 10 — Configure a Snowpipe flow
--
-- Snowpipe = continuous, SERVERLESS ingestion: a PIPE wraps a COPY INTO and
-- loads files as they arrive, billed per-file (no warehouse needed).
--
-- Two trigger modes:
--   * AUTO_INGEST = TRUE : cloud storage events (S3/SNS, Azure Event Grid)
--                          notify the pipe — needs an external stage.
--   * REST API           : you call insertFiles to nudge the pipe — works
--                          with internal stages too (what we demo here).
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE SCHEMA TRAINING_DB.RAW;

--------------------------------------------------------------------------------
-- 1. Landing table + dedicated stage for continuously arriving order files
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE RAW.ORDERS_STREAMING LIKE RAW.ORDERS;

CREATE OR REPLACE STAGE RAW.ORDERS_PIPE_STAGE
  FILE_FORMAT = RAW.FF_CSV_STANDARD
  COMMENT     = 'Files for Snowpipe continuous ingestion';

--------------------------------------------------------------------------------
-- 2. The PIPE — a named, always-on COPY INTO definition
--------------------------------------------------------------------------------
CREATE OR REPLACE PIPE RAW.ORDERS_PIPE
  AUTO_INGEST = FALSE          -- TRUE requires an external stage + cloud events
  COMMENT     = 'Continuously loads order CSVs into ORDERS_STREAMING'
AS
COPY INTO RAW.ORDERS_STREAMING
FROM @RAW.ORDERS_PIPE_STAGE
FILE_FORMAT = (FORMAT_NAME = 'RAW.FF_CSV_STANDARD');

SHOW PIPES IN SCHEMA RAW;
SELECT SYSTEM$PIPE_STATUS('RAW.ORDERS_PIPE');    -- "RUNNING"

--------------------------------------------------------------------------------
-- 3. Feed it a file
--------------------------------------------------------------------------------
-- Upload day1_snowflake_fundamentals/data/orders.csv to @RAW.ORDERS_PIPE_STAGE
-- (Snowsight: Data → ... → Stages → ORDERS_PIPE_STAGE → "+ Files",
--  or SnowSQL: PUT file:///path/orders.csv @RAW.ORDERS_PIPE_STAGE;)
--
-- With AUTO_INGEST pipes, loading now happens by itself on file arrival.
-- For our REST-mode demo, trigger a refresh (scans the stage for new files):
ALTER PIPE RAW.ORDERS_PIPE REFRESH;

-- Wait ~30-60s (Snowpipe is async), then:
SELECT COUNT(*) FROM RAW.ORDERS_STREAMING;       -- 30 rows once processed

--------------------------------------------------------------------------------
-- 4. Observe the pipe working
--------------------------------------------------------------------------------
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
       TABLE_NAME => 'RAW.ORDERS_STREAMING',
       START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())));

-- Like COPY, Snowpipe never reloads a file it has seen → re-running REFRESH
-- loads nothing new. Idempotent by design.
ALTER PIPE RAW.ORDERS_PIPE REFRESH;
SELECT COUNT(*) FROM RAW.ORDERS_STREAMING;       -- still 30

--------------------------------------------------------------------------------
-- 5. The production pattern (template — needs S3 + storage integration)
--------------------------------------------------------------------------------
-- CREATE PIPE RAW.ORDERS_PIPE_PROD AUTO_INGEST = TRUE AS
-- COPY INTO RAW.ORDERS_STREAMING
-- FROM @RAW.S3_LANDING/orders/
-- FILE_FORMAT = (FORMAT_NAME = 'RAW.FF_CSV_STANDARD');
--
-- Then: SHOW PIPES → copy "notification_channel" (an SQS ARN) → configure the
-- S3 bucket to send "object created" events there. Every file dropped in
-- s3://.../orders/ loads itself within ~a minute. Zero schedules, zero
-- warehouses — Snowpipe bills serverless credits per file.

-- Clean up
DROP PIPE IF EXISTS RAW.ORDERS_PIPE;

-- Checkpoint:
--  * Snowpipe vs scheduled COPY task: latency, cost model, when each wins?
--  * Why is Snowpipe naturally idempotent?
--  * Which Day 2 feature would you chain AFTER Snowpipe to transform newly
--    landed rows automatically? (Hint: streams + tasks.)
