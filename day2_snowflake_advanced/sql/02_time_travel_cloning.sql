--------------------------------------------------------------------------------
-- Day 2 / Exercises 8 & 12 — Time Travel & zero-copy cloning
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE SCHEMA TRAINING_DB.RAW;

--------------------------------------------------------------------------------
-- 1. Time Travel: query the past
--------------------------------------------------------------------------------
-- Simulate an "accident"
UPDATE ORDERS SET AMOUNT = 0 WHERE STATUS = 'completed';
SELECT SUM(AMOUNT) FROM ORDERS;                       -- oops, revenue is gone

-- Query the table as it was 1 minute ago
SELECT SUM(AMOUNT)
FROM ORDERS AT(OFFSET => -60);

-- Or just before the bad statement (grab its ID from Query History)
-- SELECT * FROM ORDERS BEFORE(STATEMENT => '<query_id>');

-- Restore by recreating from the past
CREATE OR REPLACE TABLE ORDERS AS
SELECT * FROM ORDERS AT(OFFSET => -60);

SELECT SUM(AMOUNT) FROM ORDERS;                       -- restored

--------------------------------------------------------------------------------
-- 2. UNDROP — Time Travel for whole objects
--------------------------------------------------------------------------------
DROP TABLE ORDERS_STAGING;
SHOW TABLES LIKE 'ORDERS_STAGING';                    -- gone
UNDROP TABLE ORDERS_STAGING;
SHOW TABLES LIKE 'ORDERS_STAGING';                    -- back

-- Retention: ALTER TABLE ORDERS SET DATA_RETENTION_TIME_IN_DAYS = 7;
-- (1 day default; up to 90 on Enterprise. Fail-safe adds 7 unqueryable days
--  recoverable only by Snowflake support.)

--------------------------------------------------------------------------------
-- 3. Zero-copy cloning: instant dev environment, no extra storage
--    (clones share micro-partitions; only changed data costs storage)
--------------------------------------------------------------------------------
CREATE OR REPLACE DATABASE TRAINING_DB_DEV CLONE TRAINING_DB;

-- Changes in the clone don't touch production:
UPDATE TRAINING_DB_DEV.RAW.CUSTOMERS SET COUNTRY = 'XX' WHERE CUSTOMER_ID = 1;

SELECT 'prod' AS env, COUNTRY FROM TRAINING_DB.RAW.CUSTOMERS     WHERE CUSTOMER_ID = 1
UNION ALL
SELECT 'dev',         COUNTRY FROM TRAINING_DB_DEV.RAW.CUSTOMERS WHERE CUSTOMER_ID = 1;

-- You can even clone from the past:
-- CREATE TABLE ORDERS_YESTERDAY CLONE ORDERS AT(OFFSET => -86400);

DROP DATABASE TRAINING_DB_DEV;   -- clean up

-- Checkpoint:
--  * Why is cloning a 10 TB database instant and (initially) free?
--  * Time Travel vs Fail-safe: who can use each, and for how long?
