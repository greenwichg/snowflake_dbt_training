--------------------------------------------------------------------------------
-- Day 5 / Exercise 25 — Design Bronze / Silver / Gold schemas in Snowflake
--
-- We give the Medallion layers first-class schemas in TRAINING_DB and grant
-- each role exactly the layer it needs.
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;

--------------------------------------------------------------------------------
-- 1. One schema per layer
--------------------------------------------------------------------------------
-- BRONZE: raw, immutable, exactly-as-received. Transient is a sensible choice:
-- it can always be re-loaded from source files, so we skip Fail-safe cost.
CREATE TRANSIENT SCHEMA IF NOT EXISTS TRAINING_DB.BRONZE
  COMMENT = 'Medallion bronze: raw data exactly as received (load-only)';

CREATE SCHEMA IF NOT EXISTS TRAINING_DB.SILVER
  COMMENT = 'Medallion silver: cleaned, typed, conformed (dbt staging)';

CREATE SCHEMA IF NOT EXISTS TRAINING_DB.GOLD
  COMMENT = 'Medallion gold: business-ready dims/facts (dbt marts)';

--------------------------------------------------------------------------------
-- 2. Move/load raw data into BRONZE
--    (Day 1 used RAW as our bronze; either keep RAW as the bronze layer, or
--     copy the tables across so the names match the architecture:)
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS TRAINING_DB.BRONZE.CUSTOMERS      CLONE TRAINING_DB.RAW.CUSTOMERS;
CREATE TABLE IF NOT EXISTS TRAINING_DB.BRONZE.ORDERS         CLONE TRAINING_DB.RAW.ORDERS;
CREATE TABLE IF NOT EXISTS TRAINING_DB.BRONZE.WEB_EVENTS_RAW CLONE TRAINING_DB.RAW.WEB_EVENTS_RAW;
-- (zero-copy clones — instant, no storage duplicated. Day 2 skill!)

--------------------------------------------------------------------------------
-- 3. Layer-aligned access: loaders write bronze, dbt reads bronze and owns
--    silver+gold, analysts read gold only.
--------------------------------------------------------------------------------
USE ROLE SECURITYADMIN;

GRANT USAGE  ON SCHEMA TRAINING_DB.BRONZE                    TO ROLE TRANSFORMER;
GRANT SELECT ON ALL    TABLES IN SCHEMA TRAINING_DB.BRONZE   TO ROLE TRANSFORMER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA TRAINING_DB.BRONZE   TO ROLE TRANSFORMER;
GRANT ALL    ON SCHEMA TRAINING_DB.SILVER                    TO ROLE TRANSFORMER;
GRANT ALL    ON SCHEMA TRAINING_DB.GOLD                      TO ROLE TRANSFORMER;

GRANT USAGE  ON SCHEMA TRAINING_DB.GOLD                      TO ROLE ANALYST;
GRANT SELECT ON ALL    TABLES IN SCHEMA TRAINING_DB.GOLD     TO ROLE ANALYST;
GRANT SELECT ON FUTURE TABLES IN SCHEMA TRAINING_DB.GOLD     TO ROLE ANALYST;
GRANT SELECT ON FUTURE VIEWS  IN SCHEMA TRAINING_DB.GOLD     TO ROLE ANALYST;
-- Note: ANALYST gets nothing on BRONZE/SILVER — gold is the contract surface.

USE ROLE SYSADMIN;
SHOW SCHEMAS IN DATABASE TRAINING_DB;

--------------------------------------------------------------------------------
-- 4. Point dbt at the layers (Exercise 26)
--------------------------------------------------------------------------------
-- a) If you copied raw into BRONZE: update `schema:` (and table names if
--    changed) in dbt_training/models/staging/_sources.yml from RAW to BRONZE.
-- b) In dbt_training/dbt_project.yml, uncomment:
--       staging:  +schema: silver
--       marts:    +schema: gold
--    dbt will build staging views into <target_schema>_SILVER and marts into
--    <target_schema>_GOLD (default generate_schema_name appends; in prod you
--    override that macro so the names are exactly SILVER / GOLD).
-- c) dbt run, then verify here:
--    SHOW VIEWS  IN SCHEMA TRAINING_DB.<your_schema>_SILVER;
--    SHOW TABLES IN SCHEMA TRAINING_DB.<your_schema>_GOLD;

-- Checkpoint:
--  * Why is BRONZE transient but GOLD permanent?
--  * Why does ANALYST get no grants below GOLD?
--  * Which materialization per layer, and why? (bronze: loaded tables,
--    silver: views, gold: tables/incremental)
