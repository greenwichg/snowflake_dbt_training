--------------------------------------------------------------------------------
-- Day 1 / Exercise 3 — Load CSV manually and via COPY INTO
--
-- Two loading paths:
--   A) Manual / UI : Snowsight "Load Data" wizard (good for small one-offs)
--   B) COPY INTO   : the scalable, scriptable bulk-load path (the real way)
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE SCHEMA TRAINING_DB.RAW;

--------------------------------------------------------------------------------
-- PATH A — Manual load via the Snowsight UI
--------------------------------------------------------------------------------
-- 1. In Snowsight: Data → Databases → TRAINING_DB → RAW → CUSTOMERS
-- 2. Click "Load Data" (top right).
-- 3. Upload day1_snowflake_fundamentals/data/customers.csv
-- 4. File format: Delimited (CSV), Header: "Skip first line", delimiter comma.
-- 5. Load, then verify:
SELECT * FROM RAW.CUSTOMERS ORDER BY CUSTOMER_ID;
SELECT COUNT(*) FROM RAW.CUSTOMERS;   -- expect 20

--------------------------------------------------------------------------------
-- PATH B — Scripted load: file format + stage + PUT + COPY INTO
--------------------------------------------------------------------------------

-- 1. A reusable FILE FORMAT describing our CSVs
CREATE OR REPLACE FILE FORMAT RAW.FF_CSV_STANDARD
  TYPE                         = 'CSV'
  FIELD_DELIMITER              = ','
  SKIP_HEADER                  = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF                      = ('', 'NULL')
  EMPTY_FIELD_AS_NULL          = TRUE
  TRIM_SPACE                   = TRUE
  ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE;

-- 2. A named INTERNAL stage to land files in
CREATE OR REPLACE STAGE RAW.CSV_STAGE
  FILE_FORMAT = RAW.FF_CSV_STANDARD
  COMMENT     = 'Internal stage for CSV loads';

-- 3. Upload the file to the stage.
--    In Snowsight: Data → Databases → TRAINING_DB → RAW → Stages → CSV_STAGE
--                  → "+ Files" → upload orders.csv
--    Or with SnowSQL CLI from your machine:
--      PUT file:///path/to/day1_snowflake_fundamentals/data/orders.csv @RAW.CSV_STAGE AUTO_COMPRESS=TRUE;

-- 4. Inspect what's in the stage — you can even query staged files directly!
LIST @RAW.CSV_STAGE;

SELECT $1 AS order_id, $2 AS customer_id, $6 AS amount
FROM @RAW.CSV_STAGE/orders.csv
(FILE_FORMAT => 'RAW.FF_CSV_STANDARD')
LIMIT 5;

-- 5. Bulk load with COPY INTO
COPY INTO RAW.ORDERS
FROM @RAW.CSV_STAGE/orders.csv
FILE_FORMAT = (FORMAT_NAME = 'RAW.FF_CSV_STANDARD')
ON_ERROR    = 'ABORT_STATEMENT';      -- alternatives: CONTINUE, SKIP_FILE

-- 6. Verify
SELECT COUNT(*) AS row_count, MIN(ORDER_DATE), MAX(ORDER_DATE) FROM RAW.ORDERS;  -- expect 30 rows

-- 7. Idempotency: run the same COPY again — note "LOAD_SKIPPED".
--    Snowflake remembers loaded files for 64 days (per table).
COPY INTO RAW.ORDERS
FROM @RAW.CSV_STAGE/orders.csv
FILE_FORMAT = (FORMAT_NAME = 'RAW.FF_CSV_STANDARD');

-- 8. Inspect load history
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
       TABLE_NAME => 'RAW.ORDERS',
       START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())));

--------------------------------------------------------------------------------
-- Optional: validate before loading (dry run)
--------------------------------------------------------------------------------
COPY INTO RAW.ORDERS_STAGING
FROM @RAW.CSV_STAGE/orders.csv
FILE_FORMAT     = (FORMAT_NAME = 'RAW.FF_CSV_STANDARD')
VALIDATION_MODE = 'RETURN_ERRORS';   -- parses files, loads nothing

--------------------------------------------------------------------------------
-- Checkpoint:
--  * Why did the second COPY load 0 rows?
--  * When would you choose ON_ERROR='CONTINUE' vs 'ABORT_STATEMENT'?
--  * Manual UI load vs COPY INTO: which would you use for a nightly feed of
--    500 files, and why?
--------------------------------------------------------------------------------
