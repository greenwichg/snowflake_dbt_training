# Exercise 1 — Create a Snowflake Trial Account & Explore Snowsight

## 1. Create the trial account

1. Go to <https://signup.snowflake.com/>.
2. Fill in your details; choose:
   - **Edition:** Enterprise (gives you multi-cluster warehouses & extended Time Travel to play with — still free for 30 days).
   - **Cloud provider / region:** any (pick the region closest to you).
3. Activate the account from the confirmation email and set your username/password.
4. Bookmark your account URL — it looks like `https://<account_identifier>.snowflakecomputing.com` or the Snowsight URL `https://app.snowflake.com/<org>/<account>`.

> The trial includes **$400 of credits**. A running XS warehouse costs 1 credit/hour, so you have plenty — but set `AUTO_SUSPEND` low (we use 60 s in the scripts) and suspend warehouses when done.

## 2. Tour of Snowsight (the web UI)

Spend ~15 minutes finding each of these:

| Area | Where | What to look at |
|---|---|---|
| **Worksheets** | Projects → Worksheets | Where you'll run all SQL today. Create one called `Day 1`. |
| **Context selector** | Top of a worksheet | Role / Warehouse / Database / Schema the worksheet runs as. |
| **Databases** | Data → Databases | Browse `SNOWFLAKE_SAMPLE_DATA` — pre-loaded sample datasets. |
| **Warehouses** | Admin → Warehouses | The default `COMPUTE_WH`. Note its size and auto-suspend. |
| **Query History** | Monitoring → Query History | Every query, its duration, and bytes scanned. |
| **Roles** | Admin → Users & Roles | Note `ACCOUNTADMIN`, `SYSADMIN`, `PUBLIC`. |

## 3. First queries

In your `Day 1` worksheet, run:

```sql
-- Who/where am I?
SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE(),
       CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_REGION();

-- Query sample data without loading anything (storage is shared!)
SELECT c_mktsegment, COUNT(*) AS customers
FROM snowflake_sample_data.tpch_sf1.customer
GROUP BY c_mktsegment
ORDER BY customers DESC;
```

Then open **Query History** and find the query you just ran — check how long it took and how much data it scanned.

## 4. Checkpoint questions

1. Which of the three architecture layers executed your query? Which layer stored the result metadata?
2. Run the sample-data query again. Why was it nearly instant the second time? (Hint: result cache lives in the Cloud Services layer.)
3. What happens to a warehouse 60 seconds after your last query if `AUTO_SUSPEND = 60`? Do you lose any data?

➡️ Next: [`sql/02_create_database_schema_tables.sql`](sql/02_create_database_schema_tables.sql)
