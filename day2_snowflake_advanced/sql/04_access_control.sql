--------------------------------------------------------------------------------
-- Day 2 / Exercise 4 — Role-based access control (RBAC)
--
-- Goal: an ANALYST role that can read ANALYTICS but cannot touch RAW,
-- and a TRANSFORMER role (used by dbt from Day 3) that builds ANALYTICS.
--------------------------------------------------------------------------------
USE ROLE SECURITYADMIN;   -- role & grant management

--------------------------------------------------------------------------------
-- 1. Create functional roles
--------------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS ANALYST     COMMENT = 'Read-only access to ANALYTICS';
CREATE ROLE IF NOT EXISTS TRANSFORMER COMMENT = 'dbt: reads RAW, builds ANALYTICS';

-- Good practice: roll custom roles up to SYSADMIN so it can manage everything
GRANT ROLE ANALYST     TO ROLE SYSADMIN;
GRANT ROLE TRANSFORMER TO ROLE SYSADMIN;

--------------------------------------------------------------------------------
-- 2. Grants for ANALYST: read-only on ANALYTICS
--------------------------------------------------------------------------------
GRANT USAGE ON WAREHOUSE TRAINING_WH                       TO ROLE ANALYST;
GRANT USAGE ON DATABASE  TRAINING_DB                       TO ROLE ANALYST;
GRANT USAGE ON SCHEMA    TRAINING_DB.ANALYTICS             TO ROLE ANALYST;
GRANT SELECT ON ALL    TABLES IN SCHEMA TRAINING_DB.ANALYTICS TO ROLE ANALYST;
GRANT SELECT ON ALL    VIEWS  IN SCHEMA TRAINING_DB.ANALYTICS TO ROLE ANALYST;
-- And objects created later (crucial - grants are not retroactive by default):
GRANT SELECT ON FUTURE TABLES IN SCHEMA TRAINING_DB.ANALYTICS TO ROLE ANALYST;
GRANT SELECT ON FUTURE VIEWS  IN SCHEMA TRAINING_DB.ANALYTICS TO ROLE ANALYST;

--------------------------------------------------------------------------------
-- 3. Grants for TRANSFORMER: read RAW, own ANALYTICS
--------------------------------------------------------------------------------
GRANT USAGE ON WAREHOUSE TRAINING_WH                    TO ROLE TRANSFORMER;
GRANT USAGE ON DATABASE  TRAINING_DB                    TO ROLE TRANSFORMER;
GRANT USAGE ON SCHEMA    TRAINING_DB.RAW                TO ROLE TRANSFORMER;
GRANT SELECT ON ALL    TABLES IN SCHEMA TRAINING_DB.RAW TO ROLE TRANSFORMER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA TRAINING_DB.RAW TO ROLE TRANSFORMER;
GRANT ALL   ON SCHEMA TRAINING_DB.ANALYTICS             TO ROLE TRANSFORMER;
GRANT CREATE SCHEMA ON DATABASE TRAINING_DB             TO ROLE TRANSFORMER; -- dbt dev schemas

--------------------------------------------------------------------------------
-- 4. Assign to yourself and test
--------------------------------------------------------------------------------
SET my_user = CURRENT_USER();
GRANT ROLE ANALYST     TO USER IDENTIFIER($my_user);
GRANT ROLE TRANSFORMER TO USER IDENTIFIER($my_user);

USE ROLE ANALYST;
SELECT * FROM TRAINING_DB.ANALYTICS.WEB_EVENTS LIMIT 5;   -- works
SELECT * FROM TRAINING_DB.RAW.CUSTOMERS LIMIT 5;          -- fails: no USAGE on RAW

USE ROLE SYSADMIN;

-- Inspect:
SHOW GRANTS TO ROLE ANALYST;
SHOW GRANTS ON SCHEMA TRAINING_DB.ANALYTICS;

-- Checkpoint:
--  * Why grant FUTURE privileges, not just ALL?
--  * Why do roles roll up to SYSADMIN instead of granting objects to users directly?
--  * Which role will dbt use on Day 3, and why not ACCOUNTADMIN?
