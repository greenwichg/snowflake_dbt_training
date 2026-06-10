--------------------------------------------------------------------------------
-- Day 1 / Exercise 2 — Create database, schemas, and tables
-- Run top-to-bottom in a Snowsight worksheet.
--------------------------------------------------------------------------------

-- Use a role that can create databases
USE ROLE SYSADMIN;

--------------------------------------------------------------------------------
-- 1. Warehouse: our compute. XS is plenty for training.
--    AUTO_SUSPEND = 60s so we never burn credits while reading.
--------------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS TRAINING_WH
  WAREHOUSE_SIZE      = 'XSMALL'
  AUTO_SUSPEND        = 60
  AUTO_RESUME         = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT             = 'Warehouse for Snowflake+dbt training';

USE WAREHOUSE TRAINING_WH;

--------------------------------------------------------------------------------
-- 2. Database and schemas — one DB, layered schemas (mirrors ELT practice):
--    RAW       = data exactly as loaded
--    ANALYTICS = transformed, query-ready data (dbt will own this from Day 3)
--------------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS TRAINING_DB
  COMMENT = 'Database for Snowflake+dbt training';

CREATE SCHEMA IF NOT EXISTS TRAINING_DB.RAW       COMMENT = 'Landing zone - raw loaded data';
CREATE SCHEMA IF NOT EXISTS TRAINING_DB.ANALYTICS COMMENT = 'Transformed, analytics-ready data';

USE DATABASE TRAINING_DB;
USE SCHEMA RAW;

--------------------------------------------------------------------------------
-- 3. Tables
--    Permanent (default)  : Time Travel + Fail-safe. For real data.
--    Transient            : Time Travel only (0-1 days), no Fail-safe. Cheaper;
--                           good for staging/raw layers that can be reloaded.
--    Temporary            : exists only for your session.
--------------------------------------------------------------------------------

-- Customers (will be loaded from customers.csv in Exercise 3)
CREATE OR REPLACE TABLE RAW.CUSTOMERS (
    CUSTOMER_ID    INTEGER       NOT NULL,
    FIRST_NAME     VARCHAR(100),
    LAST_NAME      VARCHAR(100),
    EMAIL          VARCHAR(255),
    COUNTRY        VARCHAR(50),
    SIGNUP_DATE    DATE,
    IS_ACTIVE      BOOLEAN
);

-- Orders (will be loaded from orders.csv in Exercise 3)
CREATE OR REPLACE TABLE RAW.ORDERS (
    ORDER_ID       INTEGER       NOT NULL,
    CUSTOMER_ID    INTEGER       NOT NULL,
    ORDER_DATE     DATE,
    STATUS         VARCHAR(20),
    CURRENCY       VARCHAR(3),
    AMOUNT         NUMBER(10,2)
);

-- Raw web events land as JSON into a single VARIANT column (Exercise 4)
CREATE OR REPLACE TABLE RAW.WEB_EVENTS_RAW (
    EVENT          VARIANT,
    LOADED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- A transient table example: cheaper staging
CREATE OR REPLACE TRANSIENT TABLE RAW.ORDERS_STAGING LIKE RAW.ORDERS;

-- A temporary table example: gone when your session ends
CREATE OR REPLACE TEMPORARY TABLE RAW.SCRATCH (NOTE VARCHAR);

--------------------------------------------------------------------------------
-- 4. Verify what we built
--------------------------------------------------------------------------------
SHOW SCHEMAS IN DATABASE TRAINING_DB;
SHOW TABLES  IN SCHEMA   TRAINING_DB.RAW;

-- Insert a couple of rows manually (small-scale loading)
INSERT INTO RAW.SCRATCH VALUES ('hello snowflake'), ('compute and storage are separate');
SELECT * FROM RAW.SCRATCH;

--------------------------------------------------------------------------------
-- Checkpoint:
--  * Where does the data of RAW.CUSTOMERS physically live? (Storage layer,
--    columnar micro-partitions in cloud object storage.)
--  * What did TRAINING_WH do while you ran the CREATE statements? (Almost
--    nothing - DDL is handled by the Cloud Services layer.)
--------------------------------------------------------------------------------
