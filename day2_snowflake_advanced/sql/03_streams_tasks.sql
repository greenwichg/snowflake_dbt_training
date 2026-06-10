--------------------------------------------------------------------------------
-- Day 2 / Exercise 3 — Streams & Tasks: a native CDC mini-pipeline
--
-- Goal: new rows inserted into RAW.ORDERS automatically flow into a
-- cleaned ANALYTICS.ORDERS_CLEAN table.
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;     -- (EXECUTE TASK privilege required; grant via ACCOUNTADMIN if needed:
                       --  GRANT EXECUTE TASK ON ACCOUNT TO ROLE SYSADMIN;)
USE WAREHOUSE TRAINING_WH;
USE SCHEMA TRAINING_DB.RAW;

--------------------------------------------------------------------------------
-- 1. Target table
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE TRAINING_DB.ANALYTICS.ORDERS_CLEAN (
    ORDER_ID     INTEGER,
    CUSTOMER_ID  INTEGER,
    ORDER_DATE   DATE,
    STATUS       VARCHAR(20),
    AMOUNT_USD   NUMBER(10,2),
    PROCESSED_AT TIMESTAMP_NTZ
);

--------------------------------------------------------------------------------
-- 2. STREAM: tracks changes (CDC) on RAW.ORDERS since last consumption
--------------------------------------------------------------------------------
CREATE OR REPLACE STREAM RAW.ORDERS_STREAM ON TABLE RAW.ORDERS;

-- Empty right now:
SELECT * FROM RAW.ORDERS_STREAM;

-- Insert new data → the stream picks it up
INSERT INTO RAW.ORDERS VALUES
  (2001, 3,  CURRENT_DATE, 'completed', 'EUR', 200.00),
  (2002, 10, CURRENT_DATE, 'completed', 'EUR', 80.50);

SELECT ORDER_ID, METADATA$ACTION, METADATA$ISUPDATE FROM RAW.ORDERS_STREAM;

--------------------------------------------------------------------------------
-- 3. TASK: scheduled job that consumes the stream
--    (toy FX conversion: EUR*1.10, AUD*0.65, else as-is)
--------------------------------------------------------------------------------
CREATE OR REPLACE TASK RAW.PROCESS_NEW_ORDERS
  WAREHOUSE = TRAINING_WH
  SCHEDULE  = '1 MINUTE'
  WHEN SYSTEM$STREAM_HAS_DATA('RAW.ORDERS_STREAM')   -- skip (free) if no new data
AS
INSERT INTO TRAINING_DB.ANALYTICS.ORDERS_CLEAN
SELECT
    ORDER_ID,
    CUSTOMER_ID,
    ORDER_DATE,
    STATUS,
    AMOUNT * CASE CURRENCY WHEN 'EUR' THEN 1.10
                           WHEN 'AUD' THEN 0.65
                           ELSE 1.00 END,
    CURRENT_TIMESTAMP()
FROM RAW.ORDERS_STREAM
WHERE METADATA$ACTION = 'INSERT';

ALTER TASK RAW.PROCESS_NEW_ORDERS RESUME;   -- tasks are created suspended

-- Don't want to wait a minute? Run it now:
EXECUTE TASK RAW.PROCESS_NEW_ORDERS;

--------------------------------------------------------------------------------
-- 4. Watch it work
--------------------------------------------------------------------------------
SELECT * FROM TRAINING_DB.ANALYTICS.ORDERS_CLEAN ORDER BY PROCESSED_AT DESC;

-- Stream is now empty (consumed by the task's DML):
SELECT COUNT(*) FROM RAW.ORDERS_STREAM;

-- Insert more and wait ~1 minute (or EXECUTE TASK again):
INSERT INTO RAW.ORDERS VALUES (2003, 14, CURRENT_DATE, 'completed', 'AUD', 120.00);

-- Task run history:
SELECT NAME, STATE, SCHEDULED_TIME, COMPLETED_TIME, ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME => 'PROCESS_NEW_ORDERS'))
ORDER BY SCHEDULED_TIME DESC;

--------------------------------------------------------------------------------
-- 5. IMPORTANT — clean up (a running task consumes credits)
--------------------------------------------------------------------------------
ALTER TASK RAW.PROCESS_NEW_ORDERS SUSPEND;
-- DROP TASK RAW.PROCESS_NEW_ORDERS;
-- DROP STREAM RAW.ORDERS_STREAM;

-- Checkpoint:
--  * Why does consuming a stream in DML reset it?
--  * What does the WHEN clause save you when no new data arrives?
--  * How would you chain a second task AFTER this one (task graph)?
