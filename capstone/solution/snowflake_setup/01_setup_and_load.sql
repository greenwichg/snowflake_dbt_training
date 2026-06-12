--------------------------------------------------------------------------------
-- Capstone solution / Task 31 — Load all 3 CSVs into Snowflake RAW schema
--                                using COPY INTO
--
-- Run top-to-bottom in Snowsight, then upload the three CSVs from
-- capstone/data/ to @RAW.CSV_STAGE when prompted below.
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS CAPSTONE_WH
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;
USE WAREHOUSE CAPSTONE_WH;

-- Clean database: the capstone is built from zero, separate from TRAINING_DB
CREATE DATABASE IF NOT EXISTS CAPSTONE_DB;
CREATE SCHEMA IF NOT EXISTS CAPSTONE_DB.RAW COMMENT = 'Bronze: CSV drops, exactly as received';
USE SCHEMA CAPSTONE_DB.RAW;

--------------------------------------------------------------------------------
-- 1. Raw tables — typed loosely on purpose; real typing happens in dbt staging
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE RAW.ORDERS (
    ORDER_ID     INTEGER,
    CUSTOMER_ID  INTEGER,
    PRODUCT_ID   INTEGER,
    ORDER_DATE   DATE,
    QUANTITY     INTEGER,
    UNIT_PRICE   NUMBER(10,2),
    STATUS       VARCHAR(30)          -- arrives with messy casing; cleaned in dbt
);

CREATE OR REPLACE TABLE RAW.CUSTOMERS (
    CUSTOMER_ID  INTEGER,
    NAME         VARCHAR(200),
    CITY         VARCHAR(100),        -- has NULLs
    COUNTRY      VARCHAR(10),
    SIGNUP_DATE  DATE,
    SEGMENT      VARCHAR(30)          -- has NULLs
);

CREATE OR REPLACE TABLE RAW.PRODUCTS (
    PRODUCT_ID   INTEGER,
    NAME         VARCHAR(200),
    CATEGORY     VARCHAR(100),
    COST_PRICE   NUMBER(10,2),
    SUPPLIER_ID  VARCHAR(20)          -- has NULLs
);

--------------------------------------------------------------------------------
-- 2. File format + stage (Day 1 skills)
--------------------------------------------------------------------------------
CREATE OR REPLACE FILE FORMAT RAW.FF_CSV
  TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL') EMPTY_FIELD_AS_NULL = TRUE TRIM_SPACE = TRUE;

CREATE OR REPLACE STAGE RAW.CSV_STAGE FILE_FORMAT = RAW.FF_CSV;

-- ⬆ Upload orders.csv, customers.csv, products.csv from capstone/data/
--   (Snowsight: Data → CAPSTONE_DB → RAW → Stages → CSV_STAGE → "+ Files",
--    or SnowSQL: PUT file:///path/capstone/data/*.csv @RAW.CSV_STAGE;)
LIST @RAW.CSV_STAGE;   -- expect 3 files

--------------------------------------------------------------------------------
-- 3. COPY INTO — one per table, pattern-matched (no UI wizard!)
--------------------------------------------------------------------------------
COPY INTO RAW.ORDERS    FROM @RAW.CSV_STAGE PATTERN = '.*orders.*[.]csv.*'
  FILE_FORMAT = (FORMAT_NAME = 'RAW.FF_CSV') ON_ERROR = 'ABORT_STATEMENT';
COPY INTO RAW.CUSTOMERS FROM @RAW.CSV_STAGE PATTERN = '.*customers.*[.]csv.*'
  FILE_FORMAT = (FORMAT_NAME = 'RAW.FF_CSV') ON_ERROR = 'ABORT_STATEMENT';
COPY INTO RAW.PRODUCTS  FROM @RAW.CSV_STAGE PATTERN = '.*products.*[.]csv.*'
  FILE_FORMAT = (FORMAT_NAME = 'RAW.FF_CSV') ON_ERROR = 'ABORT_STATEMENT';

--------------------------------------------------------------------------------
-- 4. Checkpoint (deliverable: RAW schema with 3 loaded tables)
--------------------------------------------------------------------------------
SELECT 'orders' AS t, COUNT(*) AS rows FROM RAW.ORDERS
UNION ALL SELECT 'customers', COUNT(*) FROM RAW.CUSTOMERS
UNION ALL SELECT 'products',  COUNT(*) FROM RAW.PRODUCTS;
-- expect: orders 60, customers 15, products 10

-- Note the mess we'll clean in dbt (task 34):
SELECT DISTINCT STATUS FROM RAW.ORDERS;            -- mixed casing
SELECT COUNT(*) FROM RAW.CUSTOMERS WHERE CITY IS NULL OR SEGMENT IS NULL;
