--------------------------------------------------------------------------------
-- Day 1 / Exercise 4 — Query JSON / VARIANT data
--
-- We load web_events.json (newline-delimited JSON) into a VARIANT column,
-- then query it with path notation and LATERAL FLATTEN.
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE SCHEMA TRAINING_DB.RAW;

--------------------------------------------------------------------------------
-- 1. File format + stage for JSON
--------------------------------------------------------------------------------
CREATE OR REPLACE FILE FORMAT RAW.FF_JSON
  TYPE            = 'JSON'
  STRIP_OUTER_ARRAY = TRUE;   -- harmless for NDJSON, required if file is one big array

CREATE OR REPLACE STAGE RAW.JSON_STAGE
  FILE_FORMAT = RAW.FF_JSON
  COMMENT     = 'Internal stage for JSON loads';

-- Upload day1_snowflake_fundamentals/data/web_events.json to JSON_STAGE
-- (Snowsight: Data → ... → Stages → JSON_STAGE → "+ Files", or SnowSQL:
--   PUT file:///path/to/web_events.json @RAW.JSON_STAGE AUTO_COMPRESS=TRUE;)
LIST @RAW.JSON_STAGE;

--------------------------------------------------------------------------------
-- 2. Load: each JSON object becomes one VARIANT row
--------------------------------------------------------------------------------
COPY INTO RAW.WEB_EVENTS_RAW (EVENT)
FROM @RAW.JSON_STAGE/web_events.json
FILE_FORMAT = (FORMAT_NAME = 'RAW.FF_JSON');

SELECT COUNT(*) FROM RAW.WEB_EVENTS_RAW;   -- expect 10
SELECT EVENT FROM RAW.WEB_EVENTS_RAW LIMIT 2;   -- click a cell to pretty-print

--------------------------------------------------------------------------------
-- 3. Path notation:  column:path.to.field  +  ::type casts
--------------------------------------------------------------------------------
SELECT
    EVENT:event_id::STRING            AS event_id,
    EVENT:event_type::STRING          AS event_type,
    EVENT:timestamp::TIMESTAMP_NTZ    AS event_ts,
    EVENT:user.customer_id::INTEGER   AS customer_id,   -- nested object
    EVENT:user.device::STRING         AS device,
    EVENT:page.url::STRING            AS page_url       -- NULL when key absent
FROM RAW.WEB_EVENTS_RAW
ORDER BY event_ts;

-- Aggregate straight off the JSON
SELECT
    EVENT:user.device::STRING AS device,
    COUNT(*)                  AS events
FROM RAW.WEB_EVENTS_RAW
GROUP BY device
ORDER BY events DESC;

--------------------------------------------------------------------------------
-- 4. Arrays: indexing and LATERAL FLATTEN
--------------------------------------------------------------------------------
-- First element of the tags array
SELECT EVENT:event_id::STRING AS event_id,
       EVENT:tags[0]::STRING  AS first_tag,
       ARRAY_SIZE(EVENT:tags) AS tag_count
FROM RAW.WEB_EVENTS_RAW;

-- One row per tag
SELECT
    EVENT:event_id::STRING AS event_id,
    t.VALUE::STRING        AS tag
FROM RAW.WEB_EVENTS_RAW,
     LATERAL FLATTEN(INPUT => EVENT:tags) t
ORDER BY event_id, tag;

-- One row per purchased line item (only purchase events have order.items)
SELECT
    EVENT:event_id::STRING          AS event_id,
    EVENT:order.order_id::INTEGER   AS order_id,
    i.VALUE:sku::STRING             AS sku,
    i.VALUE:qty::INTEGER            AS qty,
    i.VALUE:price::NUMBER(10,2)     AS unit_price,
    qty * unit_price                AS line_total
FROM RAW.WEB_EVENTS_RAW,
     LATERAL FLATTEN(INPUT => EVENT:order.items) i
WHERE EVENT:event_type::STRING = 'purchase';

--------------------------------------------------------------------------------
-- 5. Joining semi-structured to structured — the payoff of ELT
--------------------------------------------------------------------------------
SELECT
    c.FIRST_NAME || ' ' || c.LAST_NAME      AS customer,
    c.COUNTRY,
    e.EVENT:event_type::STRING              AS event_type,
    e.EVENT:timestamp::TIMESTAMP_NTZ        AS event_ts
FROM RAW.WEB_EVENTS_RAW e
JOIN RAW.CUSTOMERS c
  ON c.CUSTOMER_ID = e.EVENT:user.customer_id::INTEGER
ORDER BY event_ts;

--------------------------------------------------------------------------------
-- 6. Materialize a typed, flattened view (preview of what dbt automates)
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW ANALYTICS.WEB_EVENTS AS
SELECT
    EVENT:event_id::STRING          AS EVENT_ID,
    EVENT:event_type::STRING        AS EVENT_TYPE,
    EVENT:timestamp::TIMESTAMP_NTZ  AS EVENT_TS,
    EVENT:user.customer_id::INTEGER AS CUSTOMER_ID,
    EVENT:user.device::STRING       AS DEVICE,
    EVENT:user.browser::STRING      AS BROWSER,
    EVENT:page.url::STRING          AS PAGE_URL,
    EVENT:order.order_id::INTEGER   AS ORDER_ID,
    EVENT:order.amount::NUMBER(10,2) AS ORDER_AMOUNT
FROM RAW.WEB_EVENTS_RAW;

SELECT * FROM ANALYTICS.WEB_EVENTS ORDER BY EVENT_TS;

--------------------------------------------------------------------------------
-- Checkpoint:
--  * What does EVENT:page.url return for a purchase event, and why doesn't
--    the query error?
--  * What's the difference between EVENT:tags[0] and FLATTEN(EVENT:tags)?
--  * Why is "load raw JSON, flatten with SQL later" (ELT) more flexible than
--    flattening before load (ETL)?
--------------------------------------------------------------------------------
