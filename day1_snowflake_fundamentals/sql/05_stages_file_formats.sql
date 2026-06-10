--------------------------------------------------------------------------------
-- Day 1 / Exercise 5 — Stages and File Formats in depth
--------------------------------------------------------------------------------
USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE SCHEMA TRAINING_DB.RAW;

--------------------------------------------------------------------------------
-- 1. The three INTERNAL stage flavors
--------------------------------------------------------------------------------

-- (a) USER stage — every user has one, referenced as @~
LIST @~;

-- (b) TABLE stage — every table has one, referenced as @%<table>
LIST @%ORDERS;

-- (c) NAMED stage — created explicitly, shareable, supports default file format
CREATE OR REPLACE STAGE RAW.LANDING_STAGE
  FILE_FORMAT = RAW.FF_CSV_STANDARD
  DIRECTORY   = (ENABLE = TRUE)          -- queryable file directory
  COMMENT     = 'General-purpose internal landing stage';

SHOW STAGES IN SCHEMA RAW;

-- With DIRECTORY enabled you can query file metadata:
-- ALTER STAGE RAW.LANDING_STAGE REFRESH;
-- SELECT * FROM DIRECTORY(@RAW.LANDING_STAGE);

--------------------------------------------------------------------------------
-- 2. EXTERNAL stages — pointers to YOUR cloud storage
--    (template only: needs a real bucket + storage integration to run)
--------------------------------------------------------------------------------

-- Best practice: a STORAGE INTEGRATION (IAM-based auth, no keys in SQL).
-- Requires ACCOUNTADMIN and cloud-side IAM setup:
--
-- CREATE STORAGE INTEGRATION S3_TRAINING_INT
--   TYPE                      = EXTERNAL_STAGE
--   STORAGE_PROVIDER          = 'S3'
--   ENABLED                   = TRUE
--   STORAGE_AWS_ROLE_ARN      = 'arn:aws:iam::123456789012:role/snowflake-access'
--   STORAGE_ALLOWED_LOCATIONS = ('s3://my-training-bucket/landing/');
--
-- CREATE OR REPLACE STAGE RAW.S3_LANDING
--   URL                 = 's3://my-training-bucket/landing/'
--   STORAGE_INTEGRATION = S3_TRAINING_INT
--   FILE_FORMAT         = RAW.FF_CSV_STANDARD;
--
-- COPY INTO RAW.ORDERS FROM @RAW.S3_LANDING PATTERN = '.*orders.*[.]csv';

-- Internal vs External — when to use which:
--   Internal : training, ad-hoc loads, no cloud bucket needed; files must be
--              PUT into Snowflake first.
--   External : production pipelines; data already lands in S3/Blob/GCS;
--              enables auto-ingest (Snowpipe), data lake patterns.

--------------------------------------------------------------------------------
-- 3. File formats — one per file "shape", reused across stages & COPYs
--------------------------------------------------------------------------------

-- Pipe-delimited with a different date format and gzip compression
CREATE OR REPLACE FILE FORMAT RAW.FF_PIPE_DELIMITED
  TYPE            = 'CSV'
  FIELD_DELIMITER = '|'
  SKIP_HEADER     = 1
  DATE_FORMAT     = 'DD/MM/YYYY'
  COMPRESSION     = 'GZIP';

-- Parquet — schema travels with the file; query columns via $1:<col>
CREATE OR REPLACE FILE FORMAT RAW.FF_PARQUET
  TYPE = 'PARQUET';

SHOW FILE FORMATS IN SCHEMA RAW;
DESCRIBE FILE FORMAT RAW.FF_CSV_STANDARD;

--------------------------------------------------------------------------------
-- 4. Useful stage commands
--------------------------------------------------------------------------------
LIST @RAW.CSV_STAGE;                       -- what's staged (name, size, md5)
-- REMOVE @RAW.CSV_STAGE/orders.csv.gz;    -- delete a staged file
-- REMOVE @RAW.CSV_STAGE;                  -- delete everything in the stage

-- COPY INTO also works in reverse — UNLOAD a table to files:
COPY INTO @RAW.LANDING_STAGE/export/orders_
FROM RAW.ORDERS
FILE_FORMAT = (FORMAT_NAME = 'RAW.FF_CSV_STANDARD' COMPRESSION = 'GZIP')
HEADER      = TRUE
OVERWRITE   = TRUE;

LIST @RAW.LANDING_STAGE/export/;

--------------------------------------------------------------------------------
-- Checkpoint:
--  * Which stage type would you use for: (a) a quick personal test file,
--    (b) a shared team landing area, (c) a production S3 data lake feed?
--  * Why are storage integrations preferred over embedding cloud credentials
--    in a stage definition?
--  * One file format object can be reused by how many stages/COPY commands?
--------------------------------------------------------------------------------
