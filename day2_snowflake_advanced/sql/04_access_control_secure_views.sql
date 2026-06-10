--------------------------------------------------------------------------------
-- Day 2 / Exercise 7 — Secure views & RBAC (roles, grants, users)
--
-- Goal: an ANALYST role that can read ANALYTICS but cannot touch RAW,
-- a TRANSFORMER role (used by dbt from Day 3) that builds ANALYTICS,
-- and a SECURE VIEW that safely exposes only masked customer data.
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

--------------------------------------------------------------------------------
-- 5. SECURE VIEWS — expose data without leaking what's underneath
--------------------------------------------------------------------------------
-- A regular view's definition is visible to anyone who can use it, and the
-- optimizer may push user predicates INTO the view (which can leak rows via
-- clever filters/UDFs). A SECURE view:
--   * hides its definition from non-owners
--   * disables optimizations that could bypass its filters
--   * is REQUIRED for views used in data shares
USE ROLE SYSADMIN;

CREATE OR REPLACE SECURE VIEW TRAINING_DB.ANALYTICS.CUSTOMERS_MASKED AS
SELECT
    CUSTOMER_ID,
    FIRST_NAME,
    LEFT(LAST_NAME, 1) || '***'                          AS LAST_NAME_MASKED,
    REGEXP_REPLACE(EMAIL, '^[^@]+', '*****')             AS EMAIL_MASKED,
    COUNTRY,
    SIGNUP_DATE
FROM TRAINING_DB.RAW.CUSTOMERS
WHERE IS_ACTIVE = TRUE;            -- inactive customers are not exposed at all

GRANT SELECT ON VIEW TRAINING_DB.ANALYTICS.CUSTOMERS_MASKED TO ROLE ANALYST;

-- Test as ANALYST: masked data visible, definition hidden
USE ROLE ANALYST;
SELECT * FROM TRAINING_DB.ANALYTICS.CUSTOMERS_MASKED LIMIT 5;     -- works, masked
SELECT GET_DDL('VIEW', 'TRAINING_DB.ANALYTICS.CUSTOMERS_MASKED'); -- fails: not owner

USE ROLE SYSADMIN;
SHOW VIEWS LIKE 'CUSTOMERS_MASKED' IN SCHEMA TRAINING_DB.ANALYTICS;  -- is_secure = true

--------------------------------------------------------------------------------
-- 6. Data sharing (concept + template)
--------------------------------------------------------------------------------
-- Secure Data Sharing exposes live, read-only data to ANOTHER Snowflake
-- account with no copying — consumers query your storage with their compute.
-- (Needs a second account to fully demo; template:)
--
-- USE ROLE ACCOUNTADMIN;
-- CREATE SHARE TRAINING_SHARE;
-- GRANT USAGE ON DATABASE TRAINING_DB                         TO SHARE TRAINING_SHARE;
-- GRANT USAGE ON SCHEMA TRAINING_DB.ANALYTICS                 TO SHARE TRAINING_SHARE;
-- GRANT SELECT ON VIEW TRAINING_DB.ANALYTICS.CUSTOMERS_MASKED TO SHARE TRAINING_SHARE;
-- ALTER SHARE TRAINING_SHARE ADD ACCOUNTS = ('<consumer_account>');
--
-- Only SECURE views/UDFs can be shared — exactly why we built one above.

-- Checkpoint:
--  * Why grant FUTURE privileges, not just ALL?
--  * Why do roles roll up to SYSADMIN instead of granting objects to users directly?
--  * Which role will dbt use on Day 3, and why not ACCOUNTADMIN?
--  * Why must shared views be SECURE views?
